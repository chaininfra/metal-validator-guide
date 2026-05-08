#!/bin/bash

# ─────────────────────────────────────────────
#  MetalGo Upgrade Script
#  Run as root: sudo bash metal-upgrade.sh
# ─────────────────────────────────────────────

set -e

VERSION="v1.12.2"
BINARY_URL="https://github.com/MetalBlockchain/metalgo/releases/download/${VERSION}/metalgo-linux-amd64-${VERSION}.tar.gz"
METAL_USER="metaluser"
INSTALL_PATH="/home/${METAL_USER}/metal-node/metalgo"
TARBALL="metalgo-linux-amd64-${VERSION}.tar.gz"
EXTRACT_DIR="metalgo-${VERSION}"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()    { echo -e "${GREEN}[✔]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✘]${NC} $1"; exit 1; }

# ── Must run as root ──────────────────────────
if [ "$EUID" -ne 0 ]; then
  error "Please run as root: sudo bash $0"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MetalGo Upgrade → ${VERSION}"
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

# ── Download new binary ───────────────────────
log "Downloading metalgo ${VERSION}..."
cd /tmp
wget -q --show-progress "${BINARY_URL}" -O "${TARBALL}" || error "Download failed"
log "Download complete."

# ── Extract ───────────────────────────────────
log "Extracting..."
tar -xzf "${TARBALL}" || error "Extraction failed"

# ── Stop service ──────────────────────────────
log "Stopping metalgo service..."
systemctl disable metalgo 2>/dev/null || true
pkill -9 -f metalgo 2>/dev/null || true
sleep 2
log "Service stopped."

# ── Backup old binary ─────────────────────────
if [ -f "${INSTALL_PATH}" ]; then
  cp "${INSTALL_PATH}" "${INSTALL_PATH}.bak"
  log "Backed up old binary to ${INSTALL_PATH}.bak"
fi

# ── Copy new binary ───────────────────────────
cp "${EXTRACT_DIR}/metalgo" "${INSTALL_PATH}" || error "Failed to copy binary"
chown ${METAL_USER}:${METAL_USER} "${INSTALL_PATH}"
chmod +x "${INSTALL_PATH}"
log "New binary installed."

# ── Start service ─────────────────────────────
log "Starting metalgo service..."
systemctl enable --now metalgo || error "Failed to start service"
sleep 3

# ── Verify ────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
systemctl status metalgo --no-pager | head -5
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log "Upgrade complete! Running version:"
${INSTALL_PATH} --version 2>/dev/null || true

# ── Cleanup ───────────────────────────────────
rm -rf /tmp/${TARBALL} /tmp/${EXTRACT_DIR}
log "Cleaned up temp files."
echo ""