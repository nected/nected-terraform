#!/bin/bash
set -e

SEEDS="${seeds}"
CLUSTER_NAME="${cluster_name}"
NODE_INDEX="${node_index}"

# # Mount data disk
MOUNT="/var/lib/cassandra"



# Wait for data disk to be attached (up to 10 minutes)
echo "Waiting for data disk to be attached..."
for i in $(seq 1 60); do
  ROOT_DISK=$(lsblk -no pkname $(findmnt -n -o SOURCE /))
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

# # Find the data disk (non-root disk)
# ROOT_DISK=$(lsblk -no pkname $(findmnt -n -o SOURCE /))
# DISK=$(lsblk -dpno NAME,TYPE | awk '$2=="disk"' | grep -v "^/dev/$ROOT_DISK" | awk 'NR==1{print $1}')

# if [[ -z "$DISK" ]]; then
#   echo "ERROR: No data disk found" >&2
#   exit 1
# fi

echo "Using data disk: $DISK"

# Only format if the disk has no filesystem
if ! blkid "$DISK" &>/dev/null; then
  mkfs.xfs "$DISK"
fi

mkdir -p "$MOUNT"

# Get UUID of the disk
DISK_UUID=$(blkid -s UUID -o value "$DISK")

# Only add fstab entry if UUID not already present
if ! grep -q "$DISK_UUID" /etc/fstab; then
  echo "UUID=$DISK_UUID $MOUNT xfs defaults,nofail 0 0" >> /etc/fstab
fi

systemctl daemon-reload

mount -a

# Install Java 11
apt-get update -qq
apt-get install -y openjdk-11-jdk-headless curl gnupg

# Add Cassandra repo key (overwrite is safe, so always fetch)
mkdir -p /etc/apt/keyrings
curl -fsSL -o /etc/apt/keyrings/apache-cassandra.asc https://downloads.apache.org/cassandra/KEYS

# Only add repo if not already present
REPO_FILE="/etc/apt/sources.list.d/cassandra.sources.list"
REPO_LINE="deb [signed-by=/etc/apt/keyrings/apache-cassandra.asc] https://debian.cassandra.apache.org 50x main"
if ! grep -qF "$REPO_LINE" "$REPO_FILE" 2>/dev/null; then
  echo "$REPO_LINE" | tee "$REPO_FILE"
fi

apt-get update -qq
apt-get install -y cassandra

# Get this node's private IP
NODE_IP=$(hostname -I | awk '{print $1}')

CONF=/etc/cassandra/cassandra.yaml

set_yaml() {
  local key="$1" value="$2"
  if grep -qE "^[[:space:]]*#?[[:space:]]*$${key}:" "$CONF"; then
    sed -i -E "s|^[[:space:]]*#?[[:space:]]*$${key}:.*|$${key}: $${value}|" "$CONF"
  else
    echo "$${key}: $${value}" >> "$CONF"
  fi
}

set_yaml cluster_name "'${cluster_name}'"
set_yaml num_tokens 256
set_yaml listen_address "$NODE_IP"
set_yaml rpc_address "$NODE_IP"
set_yaml endpoint_snitch GossipingPropertyFileSnitch
set_yaml commitlog_sync periodic
set_yaml partitioner org.apache.cassandra.dht.Murmur3Partitioner
set_yaml commitlog_directory "$MOUNT/commitlog"
set_yaml hints_directory "$MOUNT/hints"
set_yaml saved_caches_directory "$MOUNT/saved_caches"

# seeds lives nested under seed_provider.parameters; preserve indentation.
sed -i -E "s|^([[:space:]]*)#?[[:space:]]*- seeds:.*|\1- seeds: \"${seeds}\"|" "$CONF"

# data_file_directories is a list. If the key is present uncommented, rewrite
# the next line (the single default entry); otherwise append a fresh block.
if grep -q '^data_file_directories:' "$CONF"; then
  sed -i "/^data_file_directories:/{n;s|.*|    - $MOUNT/data|;}" "$CONF"
else
  printf 'data_file_directories:\n    - %s/data\n' "$MOUNT" >> "$CONF"
fi

chown -R cassandra:cassandra "$MOUNT"
systemctl enable cassandra
systemctl restart cassandra