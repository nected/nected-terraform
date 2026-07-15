#!/bin/bash
set -e

# CLUSTER_NAME, ENVIRONMENT, SERVICE, PROJECT exported by Terraform user_data prefix
MOUNT="/var/lib/cassandra"

# ---------------------------------------------------------------------------
# IMDSv2 helpers
# ---------------------------------------------------------------------------
get_imds_token() {
  curl -s -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 60"
}

imds_get() {
  local imds_path="$1"
  local token
  token=$(get_imds_token)
  curl -s -H "X-aws-ec2-metadata-token: $token" \
    "http://169.254.169.254/latest/meta-data/$imds_path" | tr -d '\n'
}

echo "Waiting for private IP..."
for i in {1..60}; do
  NODE_IP=$(imds_get "local-ipv4")
  if [[ -n "$NODE_IP" ]]; then
    echo "Private IP assigned: $NODE_IP"
    sleep 10
    break
  fi
  sleep 5
done

if [[ -z "$NODE_IP" ]]; then
  echo "ERROR: No private IP assigned" >&2
  exit 1
fi

# Bootstrap: ensure curl and unzip are available before any network calls
apt-get update -qq
apt-get install -y curl unzip -qq

# ---------------------------------------------------------------------------
# Install AWS CLI v2 from official installer (all output to stderr)
# ---------------------------------------------------------------------------
install_awscli() {
  local arch
  arch=$(uname -m)
  [[ "$arch" == "arm64" ]] && arch="aarch64"
  [[ "$arch" == "amd64" ]] && arch="x86_64"

  echo "Installing AWS CLI v2 for $arch..." >&2
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip" \
    -o /tmp/awscliv2.zip >&2
  unzip -q /tmp/awscliv2.zip -d /tmp/awscliv2 >&2
  /tmp/awscliv2/aws/install --install-dir /usr/local/aws-cli --bin-dir /usr/local/bin >&2
  rm -rf /tmp/awscliv2 /tmp/awscliv2.zip
  echo "AWS CLI installed: $(aws --version 2>&1)" >&2
}

# ---------------------------------------------------------------------------
# Discover seed nodes via EC2 tags — prints only comma-separated IPs to stdout
# ---------------------------------------------------------------------------
discover_seeds() {
  local region
  region=$(imds_get "placement/region")

  echo "Discovering seeds in region $region with tags:" \
       "Environment=$ENVIRONMENT Service=$SERVICE Project=$PROJECT" >&2

  if ! command -v aws &>/dev/null; then
    install_awscli
  fi

  local raw
  # Capture stdout only; let stderr go to the log naturally
  raw=$(aws ec2 describe-instances \
    --region "$region" \
    --filters \
      "Name=tag:Environment,Values=$ENVIRONMENT" \
      "Name=tag:Service,Values=$SERVICE"         \
      "Name=tag:Project,Values=$PROJECT"         \
      "Name=tag:Ownedby,Values=nected"           \
      "Name=tag:Seed,Values=true"                \
      "Name=instance-state-name,Values=running"  \
    --query "Reservations[].Instances[].PrivateIpAddress" \
    --output text)

  echo "Raw EC2 response: [$raw]" >&2

  # Normalise: tabs and spaces to newlines, keep only valid IPs, dedupe, join with comma
  echo "$raw" \
    | tr '\t' '\n' \
    | tr ' ' '\n' \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -u \
    | tr '\n' ',' \
    | sed 's/,$//'
}

# ---------------------------------------------------------------------------
# Wait for data disk (up to 10 minutes)
# ---------------------------------------------------------------------------
echo "Waiting for data disk to be attached..."
for i in $(seq 1 60); do
  SOURCE_DEV=$(findmnt -n -o SOURCE /)
  ROOT_DISK=$(lsblk -no pkname "$SOURCE_DEV")
  DISK=$(lsblk -dpno NAME,TYPE | awk '$2=="disk"' | grep -v "^/dev/$ROOT_DISK" | awk 'NR==1{print $1}')
  if [[ -n "$DISK" ]]; then
    echo "Data disk found: $DISK"
    break
  fi
  echo "Attempt $i/60: No data disk yet, waiting 10s..."
  sleep 10
done

if [[ -z "$DISK" ]]; then
  echo "ERROR: Data disk never appeared after 10 minutes" >&2
  exit 1
fi

echo "Using data disk: $DISK"

if ! blkid "$DISK" &>/dev/null; then
  mkfs.xfs "$DISK"
fi

mkdir -p "$MOUNT"

DISK_UUID=$(blkid -s UUID -o value "$DISK")

if ! grep -q "$DISK_UUID" /etc/fstab; then
  echo "UUID=$DISK_UUID $MOUNT xfs defaults,nofail 0 0" >> /etc/fstab
fi

systemctl daemon-reload
mount -a

# ---------------------------------------------------------------------------
# Install Java 17 + Cassandra 5.x
# ---------------------------------------------------------------------------
apt-get install -y openjdk-17-jdk-headless gnupg

mkdir -p /etc/apt/keyrings
curl -fsSL -o /etc/apt/keyrings/apache-cassandra.asc https://downloads.apache.org/cassandra/KEYS

REPO_FILE="/etc/apt/sources.list.d/cassandra.sources.list"
REPO_LINE="deb [signed-by=/etc/apt/keyrings/apache-cassandra.asc] https://debian.cassandra.apache.org 50x main"
if ! grep -qF "$REPO_LINE" "$REPO_FILE" 2>/dev/null; then
  echo "$REPO_LINE" | tee "$REPO_FILE"
fi

apt-get update -qq
apt-get install -y cassandra

# Discover seeds after cassandra install (aws cli now available)
SEEDS=$(discover_seeds)

if [[ -z "$SEEDS" ]]; then
  echo "WARNING: No peer instances found via tags; using own IP as seed." >&2
  SEEDS="$NODE_IP"
fi

echo "Seeds resolved: $SEEDS"

# ---------------------------------------------------------------------------
# Configure Cassandra
# ---------------------------------------------------------------------------
CONF=/etc/cassandra/cassandra.yaml

set_yaml() {
  local k="$1" v="$2"
  if grep -qE "^[[:space:]]*#?[[:space:]]*$k:" "$CONF"; then
    sed -i -E "s|^[[:space:]]*#?[[:space:]]*$k:.*|$k: $v|" "$CONF"
  else
    echo "$k: $v" >> "$CONF"
  fi
}

CLUSTER_NAME_YAML="'${CLUSTER_NAME}'"

set_yaml cluster_name               "$CLUSTER_NAME_YAML"
set_yaml num_tokens                 256
set_yaml listen_address             "$NODE_IP"
set_yaml rpc_address                "$NODE_IP"
set_yaml endpoint_snitch            Ec2Snitch
set_yaml commitlog_sync             periodic
set_yaml partitioner                org.apache.cassandra.dht.Murmur3Partitioner
set_yaml commitlog_directory        "$MOUNT/commitlog"
set_yaml hints_directory            "$MOUNT/hints"
set_yaml saved_caches_directory     "$MOUNT/saved_caches"
set_yaml allocate_tokens_for_local_replication_factor 2
# Use python to replace seeds — avoids sed misinterpreting dots/commas in IP list
python3 - <<EOF
import re

conf_path = "$CONF"
seeds_value = "$SEEDS"

with open(conf_path, 'r') as f:
    conf = f.read()

conf = re.sub(
    r'^(\s*)-\s*seeds:.*$',
    lambda m: m.group(1) + '- seeds: "' + seeds_value + '"',
    conf,
    flags=re.MULTILINE
)

with open(conf_path, 'w') as f:
    f.write(conf)

print("Seeds written: " + seeds_value)
EOF

if grep -q '^data_file_directories:' "$CONF"; then
  sed -i "/^data_file_directories:/{n;s|.*|    - $MOUNT/data|;}" "$CONF"
else
  printf 'data_file_directories:\n    - %s/data\n' "$MOUNT" >> "$CONF"
fi

echo "=== Verification ==="
echo "cluster_name: $(grep 'cluster_name' $CONF)"
echo "seeds:        $(grep '- seeds:' $CONF)"
echo "listen:       $(grep 'listen_address' $CONF)"
echo "===================="

chown -R cassandra:cassandra "$MOUNT"
systemctl enable cassandra

rm -rf /var/lib/cassandra/data/* 

systemctl restart cassandra