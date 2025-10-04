
# 🪙 Metal Node - Validator Setup & Monitoring Guide

This repository helps you set up, validate, and monitor your **Metal Blockchain Node** using Prometheus and Grafana.

---

## 🚀 Quick Start

Clone this repo and run the installer:

```bash
git clone https://github.com/chaininfra/metal-validator-guide.git
cd metal-validator-guide/scripts
chmod +x install_monitoring.sh
./install_monitoring.sh
````

Then follow the steps in the [Validator Setup Guide](#setting-up-your-validator).

---

## 🎉 Your Metal Node is Successfully Running!

Your Metal node has been installed and is fully operational. This guide will help you set up validation and access your monitoring dashboard.

---

## 📋 Node Information

| Parameter               | Description    |
| ----------------------- | -------------- |
| **NodeID**              | `<NODE_ID>`    |
| **Public Key**          | `<PUBLIC_KEY>` |
| **Proof of Possession** | `<SIGNATURE>`  |
| **Server IP**           | `<IP_ADDRESS>` |

### Monitoring Access

* **Grafana Dashboard** → `http://<IP_ADDRESS>:3000`
* **Prometheus Metrics** → `http://<IP_ADDRESS>:9090`
* **Login** → `admin / admin` (change immediately)

---

## ⚙️ Validator Setup Steps

1. **Create Wallet** → [Metal Wallet](https://wallet.metalblockchain.org/)
2. **Fund Wallet** with METAL on the **C-Chain**
3. **Transfer to P-Chain** for staking
4. **Add Validator** via `Earn → Validate → Add Validator`

✅ Done — your node is validating!

---

## 📊 Node Monitoring

After installation:

* Access Grafana → `http://<IP_ADDRESS>:3000`
* View dashboards for:

  * Node health
  * Peer count
  * CPU/memory
  * Validation status

---

## 🛡 Security Best Practices

* Backup `staker.key` & `staker.crt`
* Restrict SSH access
* Keep your system updated
* Monitor uptime via Grafana

---

## 🧠 Next Steps

* [ ] Change Grafana password
* [ ] Add validator via Metal Wallet
* [ ] Verify validator on API
* [ ] Monitor uptime weekly
* [ ] Update software monthly

---

## 🧰 Included Script

The `install_monitoring.sh` script automates the setup of:

* **Prometheus**
* **Grafana**
* **Node Exporter**
* **MetalGo Dashboards**

You can run each step individually with:

```bash
./install_monitoring.sh --1  # Install Prometheus
./install_monitoring.sh --2  # Install Grafana
./install_monitoring.sh --3  # Install node_exporter
./install_monitoring.sh --4  # Install dashboards
```

---

## 📜 License

MIT License — free to use and share.

```

---

## 🧩 Step 2. `scripts/install_monitoring.sh`

Save your full bash installer as:

```

scripts/install_monitoring.sh

````

Make it executable:
```bash
chmod +x scripts/install_monitoring.sh
````

---

## ⚖️ Step 3. Add a License (MIT recommended)

Create `LICENSE`:

```text
MIT License

Copyright (c) 2025 Leenoh

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

---

## 🛠 Step 4. Push to GitHub

```bash
git init
git add .
git commit -m "Initial commit: Metal Validator Setup & Monitoring Guide"
git branch -M main
git remote add origin https://github.com/<your-username>/metal-validator-guide.git
git push -u origin main
```

---

## ✅ Optional Enhancements

* Add a **`docs/`** folder later for screenshots or Markdown pages (`docs/monitoring.md`).
* Include a **GitHub Actions workflow** to test the installer script’s syntax.
* Add badges for “ShellCheck Passed”, “MIT License”, etc.

---

