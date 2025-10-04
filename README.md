# Metal Node Setup Guide for Contabo VPS

Complete guide for setting up a Metal blockchain validator node on Contabo VPS with monitoring.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Monitoring Setup](#monitoring-setup)
- [Node Management](#node-management)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

## Prerequisites

### Hardware Requirements

- **CPU**: Equivalent of 8 AWS vCPU
- **RAM**: 16 GiB minimum
- **Storage**: 250 GiB available disk space
- **OS**: Ubuntu 18.04/20.04/22.04
- **Network**: Sustained 5Mbps up/down bandwidth

> ⚠️ **Note**: Hardware requirements scale with METAL stake amount. Nodes with 100k+ METAL stakes need more powerful machines.

### Access Requirements

- Sudo/root access to your VPS
- Static public IP address
- SSH access configured

### Network Setup

**For VPS/Cloud Servers**: Ports are usually open by default. You only need to configure firewall rules.

**For Home Networks**: You must configure port forwarding on your router. See [Port Forwarding Guide](#port-forwarding-for-home-networks) below.

## Quick Start

```bash
# 1. Connect to your VPS
ssh root@your-vps-ip

# 2. Create user (if running as root)
sudo adduser metaluser
sudo usermod -aG sudo metaluser
su - metaluser

# 3. Download and run installer
wget -nd -m https://raw.githubusercontent.com/MetalBlockchain/metal-docs/master/scripts/metalgo-installer.sh
chmod 755 metalgo-installer.sh
./metalgo-installer.sh

# 4. Get your NodeID
sudo journalctl -u metalgo | grep "NodeID"
```

## Detailed Setup

### Step 1: Initial VPS Setup

#### 1.1 Connect and Create User Account

```bash
# Connect as root
ssh root@your-vps-ip

# Create new user (replace 'metaluser' with your preferred username)
sudo adduser metaluser

# Add user to sudo group
sudo usermod -aG sudo metaluser

# Switch to the new user
su - metaluser
```

**Alternative: If you already have a non-root user:**
```bash
ssh your-username@your-vps-ip
```

#### 1.2 Update System

```bash
sudo apt update && sudo apt upgrade -y
```

#### 1.3 Verify User Setup

```bash
# Confirm you're running as non-root user
whoami
# Should NOT return 'root'

# Test sudo access
sudo whoami
# Should return 'root'
```

#### 1.4 Configure Firewall

```bash
# Allow SSH
sudo ufw allow 22/tcp

# Allow Metal node ports
sudo ufw allow 9651/tcp  # Staking port
sudo ufw allow 9650/tcp  # RPC port
sudo ufw allow 9090/tcp  # Prometheus
sudo ufw allow 3000/tcp  # Grafana

# Enable firewall
sudo ufw enable
```

### Step 2: Install Metal Node

#### 2.1 Download Installer

```bash
wget -nd -m https://raw.githubusercontent.com/MetalBlockchain/metal-docs/master/scripts/metalgo-installer.sh
chmod 755 metalgo-installer.sh
```

#### 2.2 Run Installer

```bash
./metalgo-installer.sh
```

#### 2.3 Configuration Prompts

**Connection Type:**
- Choose `2` for cloud provider (static IP)

**Public IP:**
- Confirm auto-detected VPS IP with `y`
- Or enter manually if incorrect

**RPC Access:**
- Choose `local` for security (recommended)
- Choose `any` only if remote RPC access is needed

### Step 3: Verify Installation

#### Check Node Status

```bash
sudo systemctl status metalgo
```

You should see `active (running)` status.

#### Find Your NodeID

```bash
sudo journalctl -u metalgo | grep "NodeID"
```

**Save your NodeID** (format: `NodeID-xxxxxxxxx`) - you'll need this for staking.

#### Monitor Bootstrapping

```bash
sudo journalctl -u metalgo -f
```

Press `Ctrl+C` to stop monitoring.

#### Check Bootstrap Status

```bash
curl -X POST --data '{
    "jsonrpc":"2.0",
    "id": 1,
    "method": "info.isBootstrapped",
    "params": {
        "chain": "X"
    }
}' -H 'content-type:application/json' 127.0.0.1:9650/ext/info
```

#### Get NodeID via API

```bash
curl -X POST --data '{
    "jsonrpc":"2.0",
    "id": 1,
    "method": "info.getNodeID"
}' -H 'content-type:application/json' 127.0.0.1:9650/ext/info
```

### Step 4: Backup Important Files

```bash
# Create backup directory
mkdir -p ~/metal-backup

# Backup staking certificates
cp ~/.metalgo/staking/staker.crt ~/metal-backup/
cp ~/.metalgo/staking/staker.key ~/metal-backup/

# Secure the backup
chmod 600 ~/metal-backup/staker.*
```

> ⚠️ **Critical**: Store these files securely offline. You'll need them to restore your node identity.

## Monitoring Setup

### Prerequisites Check

```bash
# Ensure Prometheus and Grafana aren't already installed
systemctl status prometheus grafana-server
```

### Step 1: Download Monitoring Installer (use script from the repo)

```bash
nano monitoring-installer.sh
chmod 755 monitoring-installer.sh
```

### Step 2: Install Components

```bash
# Install Prometheus
./monitoring-installer.sh --1

# Install Grafana
./monitoring-installer.sh --2

# Install node_exporter
./monitoring-installer.sh --3

# Install dashboards
./monitoring-installer.sh --4

# (Optional) Install additional dashboards
./monitoring-installer.sh --5
```

### Step 3: Access Grafana

- **URL**: `http://your-vps-ip:3000`
- **Default Login**: `admin` / `admin`
- **Change password** on first login

### Enable Services on Boot

```bash
sudo systemctl enable grafana-server
sudo systemctl enable prometheus
sudo systemctl enable metalgo
```

## Node Management

### Basic Commands

```bash
# Start node
sudo systemctl start metalgo

# Stop node
sudo systemctl stop metalgo

# Restart node
sudo systemctl restart metalgo

# Check status
sudo systemctl status metalgo

# View logs (live)
sudo journalctl -u metalgo -f

# View logs (paginated)
sudo journalctl -u metalgo --no-pager
```

### Configuration Files

- **Node config**: `~/.metalgo/configs/node.json`
- **C-Chain config**: `~/.metalgo/configs/chains/C/config.json`

### Example node.json

```json
{
  "http-host": "0.0.0.0",
  "http-port": 9650,
  "staking-port": 9651,
  "public-ip": "YOUR_VPS_IP",
  "db-dir": "/home/metaluser/.metalgo/db",
  "log-level": "info",
  "network-id": "mainnet",
  "index-allow-incomplete": true
}
```

### Upgrade Node

```bash
./metalgo-installer.sh
```

The installer will detect the existing installation and upgrade automatically.

## Security Best Practices

### 1. System Updates

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. SSH Security

- Use SSH keys instead of passwords
- Disable root login
- Change default SSH port

### 3. Regular Backups

- Backup staking certificates regularly
- Store backups in multiple secure locations
- Test restoration process

### 4. Monitoring

- Set up alerts in Grafana
- Monitor disk space regularly
- Track node uptime

### 5. Network Security

- Only expose necessary ports
- Use firewall rules
- Keep RPC local unless specifically needed

## Troubleshooting

### "Script is not designed to run as root user"

```bash
# Check current user
whoami

# If you're root, create and switch to regular user
adduser metaluser
usermod -aG sudo metaluser
su - metaluser

# Then run the installer
./metalgo-installer.sh
```

### Node Not Starting

```bash
# Check detailed logs
sudo journalctl -u metalgo --no-pager -l

# Check service status
sudo systemctl status metalgo
```

### Port Access Issues

```bash
# Check if ports are listening
sudo netstat -tlnp | grep :965

# Check firewall status
sudo ufw status
```

### Disk Space Issues

```bash
# Check disk usage
df -h

# Check database size
du -sh ~/.metalgo/db
```

### Monitoring Issues

```bash
# Check Prometheus
sudo systemctl status prometheus
sudo journalctl -u prometheus --no-pager

# Check Grafana
sudo systemctl status grafana-server
sudo journalctl -u grafana-server --no-pager

# Check node_exporter
sudo systemctl status node_exporter
```

## Next Steps: Staking

Once your node is fully synced:

1. **Verify Bootstrap** - Wait for complete network sync
2. **Prepare METAL** - Ensure sufficient METAL for staking
3. **Register Validator** - Use Metal wallet or CLI
4. **Monitor Performance** - Track uptime and rewards

### Important Requirements

- **Uptime**: Maintain 80%+ uptime for rewards
- **Minimum Stake**: Check current network requirements
- **Hardware**: Monitor and upgrade as needed

## Resources

- 📚 [Metal Documentation](https://docs.metalblockchain.org/)
- 🐙 [GitHub](https://github.com/MetalBlockchain)
- 🔧 [Monitoring Guide](https://docs.metalblockchain.org/nodes/maintain/setting-up-node-monitoring)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This guide is provided as-is for the Metal blockchain community.

---

**⚠️ Disclaimer**: This guide is for educational purposes. Always verify commands and configurations before running them on production systems.