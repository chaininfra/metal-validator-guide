#!/bin/bash

# ─────────────────────────────────────────────
#  MetalGo Upgrade Script
#  Run as root: sudo bash metal-upgrade.sh
# ─────────────────────────────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

METAL_USER="metaluser"
INSTALLER_URL="https://raw.githubusercontent.com/MetalBlockchain/metalgo/master/scripts/metalgo-installer.sh"

log()   { echo -e "${GREEN}[✔]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✘]${NC} $1"; exit 1; }

# ── Must run as root ──────────────────────────
if [ "$EUID" -ne 0 ]; then
  error "Please run as root: sudo bash $0"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MetalGo Upgrade Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Reset metaluser password (optional) ───────
read -p "$(echo -e ${YELLOW}[!]${NC}) Reset password for ${METAL_USER}? (y/n): " RESET_PW
if [[ "$RESET_PW" =~ ^[Yy]$ ]]; then
  echo ""
  passwd ${METAL_USER} || error "Failed to reset ${METAL_USER} password"
  log "Password updated."
else
  log "Skipping password reset."
fi
echo ""

# ── Download & run official installer ─────────
log "Downloading official MetalGo installer..."
cd /home/${METAL_USER}
rm -f metalgo-installer.sh
wget -q --show-progress "${INSTALLER_URL}" -O metalgo-installer.sh || error "Failed to download installer"
chmod +x metalgo-installer.sh
log "Running installer..."
echo ""
bash metalgo-installer.sh || error "Installer failed"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "Upgrade complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""