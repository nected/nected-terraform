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

# Configure Cassandra (writing the full config is inherently idempotent)
cat > /etc/cassandra/cassandra.yaml <<EOF
cluster_name: '${cluster_name}'
num_tokens: 256
seed_provider:
  - class_name: org.apache.cassandra.locator.SimpleSeedProvider
    parameters:
      - seeds: "${seeds}"
listen_address: $NODE_IP
rpc_address: $NODE_IP
endpoint_snitch: GossipingPropertyFileSnitch
data_file_directories:
  - $MOUNT/data
commitlog_directory: $MOUNT/commitlog
commitlog_sync: periodic
commitlog_sync_period_in_ms: 10000
partitioner: org.apache.cassandra.dht.Murmur3Partitioner
hints_directory: $MOUNT/hints
saved_caches_directory: $MOUNT/saved_caches
EOF

chown -R cassandra:cassandra "$MOUNT"
systemctl enable cassandra
systemctl restart cassandra