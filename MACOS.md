# Metal Node Setup Guide for macOS

Complete guide for running a Metal blockchain node on macOS (Intel or Apple Silicon).

## Prerequisites

### System Requirements

- **macOS**: Catalina (10.15) or newer
- **CPU**: 8 cores minimum
- **RAM**: 16 GB minimum
- **Storage**: 250 GB free disk space
- **Network**: Sustained 5Mbps up/down bandwidth

### Network Setup

**If running from home**: You must configure port forwarding on your router. See [Port Forwarding Guide](#port-forwarding-for-home-networks) below.

**If using a VPS**: Skip port forwarding - just configure firewall as shown in the main [README.md](README.md)

### Check Your System

```bash
# Check macOS version
sw_vers

# Check architecture (Intel or Apple Silicon)
uname -m
# Returns: x86_64 (Intel) or arm64 (Apple Silicon)

# Find your local IP (for port forwarding)
ipconfig getifaddr en0
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
- [Discord Community](https://discord.gg/metalblockchain)

## Port Forwarding for Home Networks

If you're running your node from home (not a VPS/cloud), you **must** configure port forwarding on your router.

### Required Ports

Forward these ports from your router to your Mac's local IP:

- **9651** (TCP) - Staking port (REQUIRED)
- **9650** (TCP) - RPC port (optional, only if you need remote access)

### Step-by-Step Guide

#### Step 1: Find Your Mac's Local IP

```bash
# WiFi
ipconfig getifaddr en0

# Ethernet
ipconfig getifaddr en1

# Or use System Preferences
# System Preferences → Network → Select connection → IP address shown
```

Note your local IP (e.g., `192.168.1.100`)

#### Step 2: Find Your Router's IP

```bash
# Get default gateway (router IP)
netstat -nr | grep default | awk '{print $2}' | head -1

# Common router IPs:
# 192.168.1.1
# 192.168.0.1
# 10.0.0.1
# 192.168.100.1
```

#### Step 3: Access Your Router

1. Open Safari (or any browser)
2. Navigate to your router's IP (e.g., `http://192.168.1.1`)
3. Login with your router credentials
   - Check router label for default login
   - Common: admin/admin, admin/password

#### Step 4: Configure Port Forwarding

**Location varies by router:**

- **Apple AirPort**: AirPort Utility → Select base station → Edit → Network → Port Settings
- **TP-Link**: Advanced → NAT Forwarding → Virtual Servers
- **Netgear**: Advanced → Advanced Setup → Port Forwarding
- **Linksys**: Security → Apps and Gaming → Single Port Forwarding
- **Asus**: WAN → Virtual Server/Port Forwarding
- **Google WiFi/Nest**: Google Home app → WiFi → Settings → Advanced → Port management
- **Eero**: Eero app → Discover → Open a port or change NAT type

#### Step 5: Add Port Forwarding Rules

Create these rules:

**Rule 1 - Staking Port (REQUIRED):**
- Service Name: `Metal-Staking`
- External Port: `9651`
- Internal Port: `9651`
- Internal IP: `YOUR_MAC_LOCAL_IP` (e.g., 192.168.1.100)
- Protocol: `TCP`
- Enable: `Yes`

**Rule 2 - RPC Port (OPTIONAL):**
- Service Name: `Metal-RPC`
- External Port: `9650`
- Internal Port: `9650`
- Internal IP: `YOUR_MAC_LOCAL_IP`
- Protocol: `TCP`
- Enable: `Yes` (only if needed)

#### Step 6: Prevent IP Changes (DHCP Reservation)

Your Mac's local IP can change. Prevent this:

**In Router:**
1. Find DHCP or LAN settings
2. Look for "DHCP Reservation" or "Static IP"
3. Bind your Mac's MAC address to its IP

**Find your Mac's MAC address:**
```bash
# WiFi
ifconfig en0 | grep ether | awk '{print $2}'

# Ethernet
ifconfig en1 | grep ether | awk '{print $2}'

# Or: System Preferences → Network → Advanced → Hardware → MAC Address
```

#### Step 7: Configure macOS Firewall

```bash
# Check if firewall is enabled
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# If enabled, allow metalgo
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/metalgo
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/local/bin/metalgo
```

**Or via GUI:**
1. System Preferences → Security & Privacy → Firewall
2. Click "Firewall Options"
3. Click "+" and add `/usr/local/bin/metalgo`
4. Set to "Allow incoming connections"

### Verify Port Forwarding

#### Test from External Tool

Visit: https://www.yougetsignal.com/tools/open-ports/

- Enter your public IP (get it from: https://ifconfig.me)
- Test port: `9651`
- Should show: "Port 9651 is open"

#### Test with Command

```bash
# Install nmap via Homebrew
brew install nmap

# Get your public IP
curl ifconfig.me

# Test from outside (use online tool or different network)
# Replace YOUR_PUBLIC_IP
nmap -p 9651 YOUR_PUBLIC_IP
```

### Troubleshooting Port Forwarding

**Port still shows closed:**

1. **Check macOS Firewall:**
   ```bash
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps | grep metalgo
   ```

2. **Verify local IP hasn't changed:**
   ```bash
   ipconfig getifaddr en0
   ```
   If changed, update router port forwarding rules

3. **Check if node is listening:**
   ```bash
   lsof -i :9651
   lsof -i :9650
   ```

4. **Test locally first:**
   ```bash
   nc -zv localhost 9651
   ```

5. **Check for VPN interference:**
   - Disable VPN temporarily
   - VPNs can block port forwarding

6. **Router restart:**
   - Unplug router for 30 seconds
   - Plug back in and wait 2-3 minutes

### Dynamic IP Considerations

If your ISP gives you a dynamic public IP:

**Option 1: Use Dynamic DNS**

```bash
# Install ddclient via Homebrew
brew install ddclient

# Or use a GUI app like:
# - No-IP DUC
# - DynDNS Updater
```

**Option 2: Check IP regularly**

```bash
# Create a script to check IP changes
cat > ~/check-ip.sh << 'EOF'
#!/bin/bash
CURRENT_IP=$(curl -s ifconfig.me)
STORED_IP=$(cat ~/.metal-ip 2>/dev/null)

if [ "$CURRENT_IP" != "$STORED_IP" ]; then
    echo "IP changed from $STORED_IP to $CURRENT_IP"
    echo "$CURRENT_IP" > ~/.metal-ip
    # Update your validator config here if needed
fi
EOF

chmod +x ~/check-ip.sh

# Run every hour via cron
(crontab -l 2>/dev/null; echo "0 * * * * ~/check-ip.sh") | crontab -
```

**Option 3: Upgrade to Static IP**
- Contact your ISP
- Request a static IP (may cost extra)

### Common Router-Specific Instructions

**Comcast/Xfinity Gateway:**
1. Visit: http://10.0.0.1
2. Login → Advanced → Port Forwarding
3. Enable bridge mode if using own router

**AT&T Router:**
1. Visit: http://192.168.1.254
2. Firewall → NAT/Gaming
3. Add custom service

**Spectrum/Charter:**
1. Visit: http://192.168.0.1 or http://192.168.1.1
2. Advanced → Port Forwarding
3. Create forwarding rules

**Eero (via app):**
1. Eero app → Discover
2. Scroll to "Open a port or change NAT type"
3. Add port forwarding rules

### Security Notes

- Only forward necessary ports (9651 is required, 9650 is optional)
- Never forward SSH port (22) unless absolutely necessary
- Keep router firmware updated
- Use strong router admin password
- Consider VPN for remote access instead of exposing RPC

---

**💡 Don't forget to vote for ChainInfra while staking XPR!**

---

**Note**: This guide is for macOS. For Linux/VPS setup, see [README.md](README.md)