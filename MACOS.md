# Metal Node Setup Guide for macOS

Complete guide for running a Metal blockchain node on macOS (Intel or Apple Silicon).

## Prerequisites

### System Requirements

- **macOS**: Catalina (10.15) or newer
- **CPU**: 8 cores minimum
- **RAM**: 16 GB minimum
- **Storage**: 250 GB free disk space
- **Network**: Sustained 5Mbps up/down bandwidth

### Check Your System

```bash
# Check macOS version
sw_vers

# Check architecture (Intel or Apple Silicon)
uname -m
# Returns: x86_64 (Intel) or arm64 (Apple Silicon)
```

## Step 1: Install Homebrew

If you don't have Homebrew installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Step 2: Install Prerequisites

```bash
brew install wget
```

## Step 3: Download and Install MetalGo

### Find the Latest Release

Visit: https://github.com/MetalBlockchain/metalgo/releases

Look for the latest release (e.g., v1.12.0-hotfix)

### Download for Your Architecture

**For Apple Silicon (M1/M2/M3):**
```bash
curl -L -o metalgo-macos.zip https://github.com/MetalBlockchain/metalgo/releases/download/v1.12.0-hotfix/metalgo-macos-v1.12.0-hotfix.zip
```

**For Intel Macs:**
```bash
curl -L -o metalgo-macos.zip https://github.com/MetalBlockchain/metalgo/releases/download/v1.12.0-hotfix/metalgo-macos-v1.12.0-hotfix.zip
```

Note: The macOS build is universal and works on both architectures.

### Extract and Install

```bash
# Unzip the download
unzip metalgo-macos.zip

# Move binary to PATH
sudo mv build/metalgo /usr/local/bin/metalgo
chmod +x /usr/local/bin/metalgo

# Verify installation
metalgo --version
```

## Step 4: Create Configuration

```bash
# Create config directory
mkdir -p ~/.metalgo/configs/chains/C

# Create node config (optional)
cat > ~/.metalgo/configs/node.json << 'EOF'
{
  "http-host": "127.0.0.1",
  "http-port": 9650,
  "staking-port": 9651,
  "db-dir": "/Users/YOUR_USERNAME/.metalgo/db",
  "log-level": "info",
  "network-id": "mainnet"
}
EOF
```

Replace `YOUR_USERNAME` with your actual macOS username.

## Step 5: Run Your Node

### Start the Node

```bash
# Get your public IP
curl ifconfig.me

# Start node with your public IP
metalgo --public-ip=YOUR_PUBLIC_IP --http-host=127.0.0.1
```

Or run with default settings:

```bash
metalgo
```

### Run in Background

```bash
# Run in background
nohup metalgo --public-ip=YOUR_PUBLIC_IP > ~/.metalgo/metalgo.log 2>&1 &

# Check if running
ps aux | grep metalgo
```

### Create LaunchAgent (Recommended)

Create a service that starts automatically:

```bash
# Create LaunchAgent directory if needed
mkdir -p ~/Library/LaunchAgents

# Create service file
cat > ~/Library/LaunchAgents/com.metal.metalgo.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.metal.metalgo</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/metalgo</string>
        <string>--http-host=127.0.0.1</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/YOUR_USERNAME/.metalgo/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/YOUR_USERNAME/.metalgo/stderr.log</string>
</dict>
</plist>
EOF

# Load the service
launchctl load ~/Library/LaunchAgents/com.metal.metalgo.plist

# Start the service
launchctl start com.metal.metalgo
```

## Step 6: Get Your NodeID

```bash
# Check logs for NodeID
grep "NodeID" ~/.metalgo/logs/main.log

# Or via API
curl -X POST --data '{
    "jsonrpc":"2.0",
    "id": 1,
    "method": "info.getNodeID"
}' -H 'content-type:application/json' 127.0.0.1:9650/ext/info
```

Save your NodeID - you'll need it for staking!

## Step 7: Verify Node is Running

```bash
# Check bootstrap status
curl -X POST --data '{
    "jsonrpc":"2.0",
    "id": 1,
    "method": "info.isBootstrapped",
    "params": {"chain": "X"}
}' -H 'content-type:application/json' 127.0.0.1:9650/ext/info

# Check peer count
curl -X POST --data '{
    "jsonrpc":"2.0",
    "id": 1,
    "method": "info.peers"
}' -H 'content-type:application/json' 127.0.0.1:9650/ext/info
```

## Step 8: Backup Staking Keys

```bash
# Create backup directory
mkdir -p ~/metal-backup

# Backup staking certificates
cp ~/.metalgo/staking/staker.{crt,key} ~/metal-backup/

# Secure permissions
chmod 600 ~/metal-backup/staker.*
```

**Important**: Store these files safely offline!

## Monitoring Setup for macOS

### Install Monitoring Tools

```bash
# Install Prometheus, Grafana, and node_exporter
brew install prometheus grafana node_exporter
```

### Start Services

```bash
# Start all monitoring services
brew services start prometheus
brew services start grafana
brew services start node_exporter
```

### Configure Prometheus

Edit Prometheus config:

```bash
nano /opt/homebrew/etc/prometheus.yml
```

Add these scrape configs:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'metalgo-machine'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          alias: 'machine'

  - job_name: 'metalgo'
    metrics_path: '/ext/metrics'
    static_configs:
      - targets: ['localhost:9650']
```

Restart Prometheus:

```bash
brew services restart prometheus
```

### Access Monitoring

- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (login: admin/admin)
- **Node Exporter**: http://localhost:9100/metrics

### Configure Grafana

1. Open Grafana at http://localhost:3000
2. Login with admin/admin (change password when prompted)
3. Add Prometheus data source:
   - Go to Configuration → Data Sources
   - Add Prometheus
   - URL: http://localhost:9090
   - Save & Test

### Import Dashboards

```bash
# Download Metal dashboards
mkdir -p ~/grafana-dashboards
cd ~/grafana-dashboards

curl -O https://raw.githubusercontent.com/MetalBlockchain/metal-monitoring/master/grafana/dashboards/c_chain.json
curl -O https://raw.githubusercontent.com/MetalBlockchain/metal-monitoring/master/grafana/dashboards/database.json
curl -O https://raw.githubusercontent.com/MetalBlockchain/metal-monitoring/master/grafana/dashboards/machine.json
curl -O https://raw.githubusercontent.com/MetalBlockchain/metal-monitoring/master/grafana/dashboards/main.json
curl -O https://raw.githubusercontent.com/MetalBlockchain/metal-monitoring/master/grafana/dashboards/network.json
curl -O https://raw.githubusercontent.com/MetalBlockchain/metal-monitoring/master/grafana/dashboards/p_chain.json
curl -O https://raw.githubusercontent.com/MetalBlockchain/metal-monitoring/master/grafana/dashboards/x_chain.json
```

Import in Grafana:
1. Go to Dashboards → Import
2. Upload each JSON file
3. Select Prometheus data source

### Useful macOS Queries

**Disk Usage (APFS filesystem):**
```
100 - (node_filesystem_avail_bytes{job="metalgo-machine", fstype="apfs"} 
       / node_filesystem_size_bytes{job="metalgo-machine", fstype="apfs"} * 100)
```

**CPU Usage:**
```
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle",job="metalgo-machine"}[5m])) * 100)
```

**Memory Usage:**
```
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100
```

**Peer Count:**
```
metal_network_peers
```

## Node Management

### Start/Stop Node (LaunchAgent)

```bash
# Stop node
launchctl stop com.metal.metalgo

# Start node
launchctl start com.metal.metalgo

# Restart node
launchctl stop com.metal.metalgo && launchctl start com.metal.metalgo

# Check status
launchctl list | grep metalgo
```

### View Logs

```bash
# Live logs
tail -f ~/.metalgo/logs/main.log

# Error logs
tail -f ~/.metalgo/stderr.log

# Check for errors
grep -i error ~/.metalgo/logs/main.log
```

### Upgrade Node

```bash
# Stop node
launchctl stop com.metal.metalgo

# Download new version
curl -L -o metalgo-macos.zip https://github.com/MetalBlockchain/metalgo/releases/download/NEW_VERSION/metalgo-macos-NEW_VERSION.zip

# Extract and replace
unzip metalgo-macos.zip
sudo mv build/metalgo /usr/local/bin/metalgo
chmod +x /usr/local/bin/metalgo

# Start node
launchctl start com.metal.metalgo
```

## Troubleshooting

### Node Won't Start

```bash
# Check if port is already in use
lsof -i :9650
lsof -i :9651

# Kill existing process
pkill metalgo
```

### Can't Access RPC

```bash
# Check if node is listening
lsof -i :9650

# Test RPC locally
curl http://localhost:9650/ext/info
```

### Low Peer Count

```bash
# Check your public IP
curl ifconfig.me

# Verify you're using the correct IP in node config
cat ~/.metalgo/configs/node.json
```

### Monitoring Not Working

```bash
# Check if services are running
brew services list

# Restart Prometheus
brew services restart prometheus

# Check Prometheus targets
open http://localhost:9090/targets
```

## macOS-Specific Notes

- macOS uses **APFS** filesystem (not ext4 like Linux)
- Use **launchctl** instead of systemctl for services
- Use **Homebrew** instead of apt-get for packages
- Node Exporter metrics will show macOS-specific labels
- Firewall configuration: System Preferences → Security & Privacy → Firewall

## Next Steps

1. Wait for your node to fully bootstrap
2. Acquire METAL tokens for staking
3. Register as a validator
4. Monitor your node's performance and uptime

## Resources

- [Metal Documentation](https://docs.metalblockchain.org/)
- [GitHub Releases](https://github.com/MetalBlockchain/metalgo/releases)

---

**Note**: This guide is for macOS. For Linux/VPS setup, see [README.md](README.md)