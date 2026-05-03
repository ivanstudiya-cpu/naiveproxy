<div align="center">

🌐 **Language:** [🇷🇺 Русский](README.md) | [🇬🇧 English](README_EN.md)

</div>

<div align="center">

```
███╗   ██╗ █████╗ ██╗██╗   ██╗███████╗    ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗
████╗  ██║██╔══██╗██║██║   ██║██╔════╝    ██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝
██╔██╗ ██║███████║██║██║   ██║█████╗      ██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝
██║╚██╗██║██╔══██║██║╚██╗ ██╔╝██╔══╝      ██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝
██║ ╚████║██║  ██║██║ ╚████╔╝ ███████╗    ██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║
╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝
                                                                         MANAGER
```

**Professional private proxy server manager**
Caddy 2 · NaiveProxy · Telegram Bot · DNS Ad Blocking · Diagnostics · SSH Hardening

---

[![Version](https://img.shields.io/badge/version-4.2.1-D4A017?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ivanstudiya-cpu/naiveproxy/releases)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-3FB950?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.shellcheck.net)
[![Bash](https://img.shields.io/badge/Bash-5.0+-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Caddy](https://img.shields.io/badge/Caddy-auto-00ADD8?style=for-the-badge&logo=caddy&logoColor=white)](https://caddyserver.com)
[![License](https://img.shields.io/badge/License-MIT-58A6FF?style=for-the-badge)](LICENSE)

---

[**Quick Start**](#-quick-start) • [**Features**](#-features) • [**Telegram Bot**](#-telegram-bot) • [**DNS Blocking**](#-dns-ad-blocking) • [**Diagnostics**](#-diagnostics) • [**FAQ**](#-faq)

</div>

---

<div align="center">

🔔 **Updates released once a month**

[![Telegram](https://img.shields.io/badge/Telegram-Channel-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/+XVSkY6blCTY0ZDU6)
[![Website](https://img.shields.io/badge/Website-ivan--it.net-D4A017?style=for-the-badge&logo=googlechrome&logoColor=white)](https://ivan-it.net)
[![GitHub](https://img.shields.io/badge/GitHub-ivanstudiya--cpu-3FB950?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ivanstudiya-cpu/naiveproxy)

</div>

---

## 🤔 What is this

**NaiveProxy** disguises traffic as Chrome browser using the real Chromium network stack. DPI systems and censors see legitimate HTTPS/2 — and let it through.

**NaiveProxy Manager** — a single bash script that turns a bare VPS into a fully protected proxy server with ad blocking and Telegram management.

```
┌─────────────┐     ┌──────────────┐     ┌───────────────────────────┐     ┌──────────┐
│  Your       │     │  Censor/DPI  │     │   Your VPS                │     │          │
│  phone      │────▶│              │────▶│   Caddy + NaiveProxy      │────▶│ Internet │
│  laptop     │     │  Sees Chrome │     │   unbound DNS blocking    │     │          │
└─────────────┘     │  HTTPS/2 ✓   │     │   probe_resistance        │     └──────────┘
 naive-client        └──────────────┘     └───────────────────────────┘
 Chromium stack       Passes through       ads blocked 🚫
```

---

## ⚡ Quick Start

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ivanstudiya-cpu/naiveproxy/main/naiveproxy.sh)
```

### Installation steps:

```
[1/5] 🔄  System Update
         apt upgrade + unattended-upgrades
         → skip if updated: press n

[2/5] 🔒  SSH Hardening                              [OPTIONAL]
         ED25519 key · auto-save · new user · Fail2Ban
         → skip if SSH configured: press n

[3/5] 📦  Building Caddy
         git clone klzgrad/forwardproxy@naive
         xcaddy build with auto version detection  ~5-15 min

[4/5] ⚙️   Configuration
         Caddyfile (:443, domain) · systemd · UFW · BBR · Telegram

[5/5] ✅  Done
         URI + JSON configs + QR code for phone
```

---

## ✨ Features

<table>
<tr>
<td width="50%" valign="top">

### 🔐 Security
- **SSH Hardening** — ED25519 key, port change, root block
- **SSH key auto-save** — to `/etc/naiveproxy/ssh_private_key`
- **Fail2Ban 3 levels** — bruteforce(7d) / DDoS(7d) / recidive(30d)
- **UFW** — deny all incoming + scanner port blocking
- **probe_resistance** — looks like a normal website
- **Camouflage page** — DevStack IT blog

### 📡 Proxy
- **Automatic TLS** — Let's Encrypt via Caddy
- **HTTP/2 + HTTP/3** — explicitly enabled
- **QR code** — one-scan phone connection
- **Multi-user** — add users without restart
- **Multiple domains** — on one server
- **TCP BBR** — optional speed boost

</td>
<td width="50%" valign="top">

### 🚫 DNS Ad Blocking
- **~1.5M domains** — ads, trackers, malware
- **unbound** — fast local resolver
- **DNS-over-TLS** — encrypted upstream queries
- **3 blocklist sources** — StevenBlack, AdAway, Hagezi
- **Whitelist** — allow specific domains
- **Auto-update** — fresh lists on schedule

### 🤖 Telegram Bot
- **16 commands** — full server management from Telegram
- **Multi-admin** — multiple administrators
- **QR code as image** — sent directly to chat
- **/adduser /deluser** — user management
- **/diagnose** — diagnostics from Telegram
- **System service** — runs 24/7

### 🔍 Diagnostics
- **7 check blocks** — Caddy, TLS, network, DNS, firewall, resources, logs
- **Color report** — ✅ / ⚠️ / ❌ per check
- **Send to Telegram** — one click

</td>
</tr>
</table>

---

## 📋 Requirements

| | |
|--|--|
| **OS** | Ubuntu 20.04 / 22.04 / 24.04 |
| **Rights** | root |
| **Domain** | A-record → server IP |
| **Ports** | 80/tcp · 443/tcp · 443/udp |
| **RAM** | 512 MB+ |
| **Disk** | 1 GB+ |

---

## 🎮 Menu

```
──────────────────────────────────────────────────────
   NaiveProxy Manager v4.2.0  [ENG]
   Status: ● running  │  Domain: proxy.example.com
   Telegram: connected  │  Users: 3  │  SSH: 52847
──────────────────────────────────────────────────────
   1)  Install NaiveProxy          10) Logs
   2)  Status + certificate        11) Remove NaiveProxy
   3)  Client config + QR          16) 🔍 Diagnostics
   4)  Users                       17) 🚫 DNS Ad Blocker
   5)  Domains                     ──────────────────
   6)  Monitoring + stats          12) 🔒 SSH Hardening
   7)  Telegram + Bot setup        13) 🔄 Update system
   8)  Restart Caddy               14) ⬆️  Update script
   9)  Update Caddy                15) 🎭 Update camouflage
──────────────────────────────────────────────────────
```

### All CLI commands:

```bash
sudo bash naiveproxy.sh install        # Full installation
sudo bash naiveproxy.sh status         # Status + certificate
sudo bash naiveproxy.sh config         # Config + QR code
sudo bash naiveproxy.sh qr             # QR code only
sudo bash naiveproxy.sh cert           # Certificate only
sudo bash naiveproxy.sh users          # User management
sudo bash naiveproxy.sh domains        # Domain management
sudo bash naiveproxy.sh monitor        # Monitoring
sudo bash naiveproxy.sh restart        # Restart Caddy
sudo bash naiveproxy.sh update         # Update Caddy
sudo bash naiveproxy.sh logs           # Live logs
sudo bash naiveproxy.sh tg-stats       # Stats to Telegram
sudo bash naiveproxy.sh bot            # Run Telegram bot
sudo bash naiveproxy.sh bot-install    # Bot as system service
sudo bash naiveproxy.sh dns            # DNS blocker menu
sudo bash naiveproxy.sh dns-install    # Install DNS blocker
sudo bash naiveproxy.sh dns-update     # Update blocklists
sudo bash naiveproxy.sh dns-status     # DNS blocker status
sudo bash naiveproxy.sh diagnose       # System diagnostics
sudo bash naiveproxy.sh ssh-hardening  # SSH Hardening
sudo bash naiveproxy.sh ssh-key        # Show SSH key
sudo bash naiveproxy.sh sysupdate      # System update
sudo bash naiveproxy.sh self-update    # Update script
sudo bash naiveproxy.sh camouflage     # Reinstall camouflage
sudo bash naiveproxy.sh version        # Version
sudo bash naiveproxy.sh remove         # Remove everything
```

---

## 🤖 Telegram Bot

Full server management directly from Telegram.

### Start:

```bash
# Manual test:
sudo bash naiveproxy.sh bot

# As system service (auto-start):
sudo bash naiveproxy.sh bot-install

# Stop:
systemctl stop naiveproxy-bot
```

### All bot commands:

| Command | Action |
|---------|--------|
| `/help` | List all commands |
| `/status` | Status + RAM + disk + cert |
| `/stats` | Full statistics |
| `/diagnose` | 7-block diagnostics |
| `/logs` | Last 20 log lines |
| `/cert` | TLS certificate status 🟢/🟡/🔴 |
| `/users` | List users |
| `/adduser login pass` | Add user |
| `/deluser login` | Remove user |
| `/qr login` | QR code image to chat |
| `/restart` | Restart Caddy |
| `/update` | Update Caddy |
| `/selfupdate` | Check script updates |
| `/admins` | List administrators |
| `/addadmin ID` | Add administrator |
| `/deladmin ID` | Remove administrator |

### Multi-admin:

```
/addadmin 987654321   ← add second admin
/admins               ← view list
```

All commands are protected — outsiders get `⛔ Access denied`.

---

## 🚫 DNS Ad Blocking

Blocks ads and trackers at DNS level — works for **all devices** connected through the proxy.

```bash
sudo bash naiveproxy.sh dns-install    # Install
sudo bash naiveproxy.sh dns-update     # Update blocklists
sudo bash naiveproxy.sh dns-status     # Status and test
sudo bash naiveproxy.sh dns            # Menu
```

### How it works:

```
Phone → NaiveProxy → unbound (127.0.0.1:5335)
                          ↓
             ads.google.com → REFUSE ❌ (blocked)
             youtube.com → Cloudflare DoT ✅ (works)
```

### Blocklist sources (~1.5M domains):

| Source | Blocks |
|--------|--------|
| StevenBlack/hosts | Ads + malware |
| AdAway | Mobile ads |
| Hagezi Pro | Aggressive blocking |

### If something breaks — whitelist:

```bash
sudo bash naiveproxy.sh dns
# → 4) Allow domain
```

---

## 🔍 Diagnostics

```bash
sudo bash naiveproxy.sh diagnose
```

```
[1/7] Caddy          ✅ running · ✅ naive padding · ✅ module
[2/7] Configuration  ✅ :443,domain · ✅ users · ✅ valid
[3/7] TLS & Network  ✅ DNS · ✅ ports · ✅ ALPN h2 · ✅ cert
[4/7] Firewall       ✅ UFW · ✅ Fail2Ban active
[5/7] Resources      ✅ RAM 40% · ✅ Disk 37% · ✅ CPU 6%
[6/7] Logs           ✅ no errors · ℹ️ 47 CONNECT tunnels
[7/7] Version        ✅ up to date · ✅ SSH hardening done

📊 RESULT: ✅ 18  ⚠️ 0  ❌ 0
🎉 Everything is working great!
```

---

## ⚠️ Critical — Caddyfile

```bash
# ❌ WRONG — clients won't connect:
your-domain.com:443 { ... }

# ✅ CORRECT — :443 must be FIRST:
:443, your-domain.com {
  tls your@email.com
  forward_proxy {
    basic_auth USERNAME PASSWORD
    hide_ip
    hide_via
    probe_resistance
  }
  file_server { root /var/www/html }
}
```

---

## 🔒 SSH Hardening

```bash
sudo bash naiveproxy.sh ssh-hardening
```

> 💡 **Can be skipped** by pressing `n` during installation.

**5 steps:** new sudo user → ED25519 key (auto-save) → port change → sshd_config → UFW + Fail2Ban

```bash
# Download SSH key:
scp root@YOUR_IP:/etc/naiveproxy/ssh_private_key ~/.ssh/id_naiveproxy
chmod 600 ~/.ssh/id_naiveproxy

# Show key anytime:
sudo bash naiveproxy.sh ssh-key
```

**Fail2Ban 3 levels:**

| Level | Trigger | Ban |
|-------|---------|-----|
| Bruteforce | 3 wrong passwords | **7 days** |
| DDoS | 10 attempts in 1 min | **7 days** |
| Recidivist | Repeated violations | **30 days** |

---

## 📱 Client Apps

### URI:
```
naive+https://USERNAME:PASSWORD@YOUR_DOMAIN:443
```

### JSON (naive-client):
```json
{
  "listen": "socks://127.0.0.1:1080",
  "proxy": "https://USERNAME:PASSWORD@YOUR_DOMAIN:443",
  "log": "naive.log"
}
```

| Client | Platform | How to add |
|--------|----------|------------|
| [NekoBox](https://github.com/MatsuriDayo/NekoBoxForAndroid/releases) | Android | QR / URI |
| [Shadowrocket](https://apps.apple.com/app/shadowrocket/id932747118) | iPhone | URI ($2.99) |
| [Hiddify](https://github.com/hiddify/hiddify-next/releases) | Windows / macOS | URI |
| [naive](https://github.com/klzgrad/naiveproxy/releases) | Windows / Linux | config.json |

> ⚠️ **v2rayNG does NOT support NaiveProxy.** Use NekoBox or Hiddify.

---

## 📁 File Structure

```
/usr/local/bin/caddy
/etc/caddy/Caddyfile                       (chmod 600)
/etc/naiveproxy/
├── naive.conf                             (chmod 600)
├── users.conf                             (chmod 600)
├── ssh_private_key                        ← SSH key
├── ssh_public_key
├── dns_stats                              ← DNS statistics
├── monitor.sh
├── .ssh_hardened
├── .sysupdate_done
└── backups/
/etc/unbound/
├── unbound.conf.d/naiveproxy-dns.conf     ← DNS config
├── blocklist.conf                         ← ~1.5M domains
└── whitelist.txt                          ← allowed domains
/etc/fail2ban/jail.local
/etc/systemd/system/
├── caddy.service
└── naiveproxy-bot.service                 ← Telegram bot
/var/www/html/index.html                   ← camouflage page
/var/log/caddy/access.log
/var/log/caddy/naive.log
```

---

## ❓ FAQ

<details>
<summary><b>Client won't connect</b></summary>

```bash
# Run diagnostics:
sudo bash naiveproxy.sh diagnose

# Check Caddyfile:
cat /etc/caddy/Caddyfile | grep ":443"
# Should be: :443, your-domain.com {

# Check ALPN:
openssl s_client -connect YOUR_DOMAIN:443 -alpn h2 2>/dev/null | grep "ALPN protocol"
# Should be: ALPN protocol: h2
```

</details>

<details>
<summary><b>DNS blocking breaks a website</b></summary>

```bash
sudo bash naiveproxy.sh dns
# → 4) Allow domain → enter domain name
```

</details>

<details>
<summary><b>How to download SSH key</b></summary>

```bash
scp root@YOUR_IP:/etc/naiveproxy/ssh_private_key ~/.ssh/id_naiveproxy
chmod 600 ~/.ssh/id_naiveproxy
ssh -i ~/.ssh/id_naiveproxy -p NEW_PORT user@YOUR_IP
```

</details>

<details>
<summary><b>Locked out after SSH hardening</b></summary>

```bash
# Access via VNC/KVM hosting console:
ufw allow 22/tcp && systemctl restart sshd
```

</details>

<details>
<summary><b>Telegram bot not responding</b></summary>

```bash
systemctl status naiveproxy-bot
journalctl -u naiveproxy-bot -n 20 --no-pager
# Restart:
systemctl restart naiveproxy-bot
```

</details>

---

## 📊 Comparison

| Feature | **NaiveProxy Manager** | x-ui / 3x-ui | Marzban |
|---------|:---:|:---:|:---:|
| No Docker | ✅ | ❌ | ❌ |
| SSH Hardening | ✅ | ❌ | ❌ |
| SSH key auto-save | ✅ | ❌ | ❌ |
| QR code | ✅ | ❌ | ❌ |
| **DNS Ad Blocking** | ✅ | ❌ | ❌ |
| **Telegram bot commands** | ✅ 16 cmds | ⚠️ basic | ⚠️ basic |
| System diagnostics | ✅ | ❌ | ❌ |
| Fail2Ban 3 levels | ✅ | ❌ | ❌ |
| Camouflage page | ✅ | ❌ | ❌ |
| Self-update | ✅ | ❌ | ❌ |
| Correct Caddyfile | ✅ v3.7+ | — | — |
| ShellCheck passing | ✅ | — | — |

---

## 📜 Changelog

<details>
<summary><b>v4.2.0</b> — DNS Ad Blocker ← CURRENT</summary>

- ✨ DNS ad blocking via unbound (~1.5M domains)
- ✨ DNS-over-TLS (Cloudflare + Google)
- ✨ Whitelist for allowing blocked domains
- ✨ Menu → 17) DNS Ad Blocker
- 🆕 CLI: `dns`, `dns-install`, `dns-update`, `dns-status`

</details>

<details>
<summary><b>v4.1.0</b> — Security Audit</summary>

- 🔒 from_id validation in bot (numbers only)
- 🔒 Command length limit 256 + args sanitization
- 🔒 Strict /addadmin validation (5-15 digits)
- 🔒 Overflow protection in polling offset
- 🐛 Fixed DIM variable (unbound variable error)

</details>

<details>
<summary><b>v4.0.0</b> — Telegram Bot</summary>

- ✨ Full Telegram bot with 16 commands
- ✨ Multi-admin support
- ✨ QR code as image to Telegram
- ✨ naiveproxy-bot system service

</details>

<details>
<summary><b>v3.9.0</b> — Diagnostics</summary>

- ✨ Full system diagnostics — 7 blocks, 18+ checks
- ✨ Send report to Telegram

</details>

<details>
<summary><b>v3.8.0</b> — Security & UX</summary>

- ✨ SSH key auto-save + scp command
- ✨ QR code in terminal
- 🛡️ UFW deny all + scanner blocking
- 🛡️ Fail2Ban 3 protection levels

</details>

<details>
<summary><b>v3.7.0</b> — Critical Fix</summary>

- 🔴 Critical Caddyfile fix: `:443, domain` not `domain:443`

</details>

<details>
<summary><b>v3.0–3.6</b> — Core</summary>

- System update, SSH Hardening, Self-update, Domains, Camouflage, Build fix

</details>

---

## 📄 License

MIT © [ivanstudiya-cpu](https://github.com/ivanstudiya-cpu)

---

<div align="center">

**If this helped — leave a ⭐ star**

[![GitHub stars](https://img.shields.io/github/stars/ivanstudiya-cpu/naiveproxy?style=for-the-badge&color=D4A017)](https://github.com/ivanstudiya-cpu/naiveproxy/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/ivanstudiya-cpu/naiveproxy?style=for-the-badge&color=58A6FF)](https://github.com/ivanstudiya-cpu/naiveproxy/network)

📱 [Telegram channel](https://t.me/+XVSkY6blCTY0ZDU6) · 🌐 [ivan-it.net](https://ivan-it.net) · 💻 [GitHub](https://github.com/ivanstudiya-cpu/naiveproxy)

*NaiveProxy Manager · by Ivan Yurievich · Updates once a month*

</div>
