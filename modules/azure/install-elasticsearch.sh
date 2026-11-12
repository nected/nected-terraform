#!/bin/bash

# === Variables ===
ES_VERSION="${elasticsearch_version}"
# Decoded from base64 rather than templated in directly. templatefile() pastes
# the literal password into this file and bash then expands it, so a value
# containing $2 loses those characters and the VM ends up with a DIFFERENT
# password from the one terraform records - every client then gets 401 with no
# clue why. Base64 output is [A-Za-z0-9+/=], so nothing in it can be expanded,
# and this holds for any password an operator supplies, not just generated ones.
ELASTIC_PASSWORD="$(printf '%s' '${elasticsearch_password_b64}' | base64 -d)"
ES_USER="elastic"
ES_HOME="/etc/elasticsearch"
ES_SERVICE="elasticsearch"

# === Update System ===
apt-get update -y
apt-get upgrade -y

# === Install Dependencies ===
apt-get install -y wget apt-transport-https openjdk-17-jdk gnupg unzip curl expect

# === Import Elasticsearch GPG Key ===
if [ ! -f /usr/share/keyrings/elasticsearch-keyring.gpg ]; then
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
else
  echo "Elasticsearch GPG key already exists, skipping import."
fi

# === Add Elasticsearch Repository ===
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list

# === Install Elasticsearch ===
apt-get update && apt-get install -y elasticsearch=$ES_VERSION
mkdir -p /usr/share/elasticsearch/logs
chown elasticsearch:elasticsearch /usr/share/elasticsearch -R

# === Wait for Elasticsearch to Start ===
echo "Waiting for Elasticsearch to start..."
sleep 30


# === Configure elasticsearch.yml ===
bash -c "cat > $ES_HOME/elasticsearch.yml" <<EOF
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: false
xpack.security.http.ssl.enabled: false
xpack.security.enrollment.enabled: false
discovery.type: single-node
network.host: 0.0.0.0
EOF

# === Restart Elasticsearch ===
systemctl daemon-reexec
systemctl enable elasticsearch
systemctl start elasticsearch

echo "Waiting for Elasticsearch to start..."
sleep 30

# === Write expect script inline ===
cat <<'EOF' > reset-password.expect
#!/usr/bin/expect -f

set timeout 60
set password [lindex $argv 0]

spawn /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i

expect {
    -re "Please confirm.*\[y/N\]" {
        send "y\r"
        exp_continue
    }
    -re "Enter password.*:" {
        send "$password\r"
        exp_continue
    }
    -re "Re-enter password.*:" {
        send "$password\r"
    }
}
expect eof
EOF

# === Make it executable ===
chmod +x reset-password.expect

# === Make it executable ===
chmod +x reset-password.expect

# === Run the expect script ===
./reset-password.expect "$ELASTIC_PASSWORD"

# === Clean up expect script (optional) ===
rm -f reset-password.expect