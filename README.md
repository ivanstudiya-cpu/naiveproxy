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

**Профессиональный менеджер приватного прокси-сервера**  
Caddy 2 · NaiveProxy · Let's Encrypt · Telegram · SSH Hardening · QR подключение

---

[![Version](https://img.shields.io/badge/version-3.8.0-D4A017?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ivanstudiya-cpu/naiveproxy/releases)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-3FB950?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.shellcheck.net)
[![Bash](https://img.shields.io/badge/Bash-5.0+-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Caddy](https://img.shields.io/badge/Caddy-auto-00ADD8?style=for-the-badge&logo=caddy&logoColor=white)](https://caddyserver.com)
[![License](https://img.shields.io/badge/License-MIT-58A6FF?style=for-the-badge)](LICENSE)

---

[**Быстрый старт**](#-быстрый-старт) • [**Возможности**](#-возможности) • [**SSH Hardening**](#-ssh-hardening) • [**Firewall**](#-firewall) • [**Клиенты**](#-клиентские-приложения) • [**FAQ**](#-faq)

</div>

---

## 🤔 Что это

**NaiveProxy** маскирует трафик под браузер Chrome используя настоящий Chromium network stack. DPI и цензоры видят легитимный HTTPS/2 — и пропускают.

**NaiveProxy Manager** — один bash-скрипт который превращает голый VPS в полноценный защищённый прокси-сервер. Без Docker, без GUI панелей, без лишних зависимостей.

```
┌─────────────┐     ┌──────────────┐     ┌───────────────────┐     ┌──────────────┐
│  Твой       │     │  Цензор/DPI  │     │   Твой VPS        │     │              │
│  телефон    │────▶│              │────▶│   Caddy +         │────▶│  Интернет    │
│  ноутбук    │     │  Видит Chrome│     │   forwardproxy    │     │              │
└─────────────┘     │  HTTPS/2 ✓   │     │   probe_resist.   │     └──────────────┘
 naive-client        └──────────────┘     └───────────────────┘
 Chromium stack       Пропускает           TLS от Let's Encrypt
```

---

## ⚡ Быстрый старт

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ivanstudiya-cpu/naiveproxy/main/naiveproxy.sh)
```

### Что происходит при установке:

```
[1/5] 🔄  Обновление системы
         apt upgrade + unattended-upgrades
         → можно пропустить: нажми n

[2/5] 🔒  SSH Hardening                              [ОПЦИОНАЛЬНО]
         ED25519 ключ · авто-сохранение · новый пользователь · Fail2Ban
         → пропусти если SSH уже настроен: нажми n

[3/5] 📦  Сборка Caddy
         git clone klzgrad/forwardproxy@naive
         xcaddy build с автоопределением версии  ~5-15 минут

[4/5] ⚙️   Настройка
         Caddyfile (:443, domain) · systemd · UFW · BBR · Telegram

[5/5] ✅  Готово
         URI + JSON конфиги + QR код для телефона
```

---

## ✨ Возможности

<table>
<tr>
<td width="50%" valign="top">

### 🔐 Безопасность
- **SSH Hardening** — ED25519 ключ, смена порта, блокировка root
- **Авто-сохранение SSH ключа** — в `/etc/naiveproxy/ssh_private_key`
- **Fail2Ban 3 уровня** — брутфорс/DDoS/рецидив
- **UFW** — deny all incoming + блокировка портов сканеров
- **probe_resistance** — выглядит как обычный сайт
- **Страница-камуфляж** — IT-блог DevStack

### 📡 Прокси
- **Автоматический TLS** — Let's Encrypt через Caddy
- **HTTP/2 + HTTP/3** — явно включены
- **QR код** — подключение одним сканом с телефона
- **Мультипользователь** — добавление без рестарта
- **Несколько доменов** — на одном сервере
- **TCP BBR** — опциональное ускорение

</td>
<td width="50%" valign="top">

### 🤖 Автоматизация
- **Telegram-бот** — алерты + статистика по команде
- **Watchdog** — cron каждые 5 минут, автоперезапуск
- **Автообновление Caddy** — каждое воскресенье 3:00
- **Self-update** — обновление скрипта с GitHub
- **Проверка сертификата** — алерт при < 7 дней

### 🛡️ Качество кода
- `set -euo pipefail` — строгий режим
- **SHA256-верификация** Go бинарника
- `grep -vF` вместо `sed` — нет regex injection
- `--data-urlencode` для Telegram
- `trap` cleanup временных файлов
- **ShellCheck passing** — 0 предупреждений

</td>
</tr>
</table>

---

## 📋 Требования

| | |
|--|--|
| **ОС** | Ubuntu 20.04 / 22.04 / 24.04 |
| **Права** | root |
| **Домен** | A-запись → IP сервера |
| **Порты** | 80/tcp · 443/tcp · 443/udp |
| **RAM** | от 512 MB |
| **Диск** | от 1 GB |

---

## 🎮 Меню

```
──────────────────────────────────────────────────────
   NaiveProxy Manager v3.8.0
   Статус: ● работает  │  Домен: proxy.example.com
   Telegram: подключён  │  Юзеров: 3  │  SSH: 52847
──────────────────────────────────────────────────────
   1)  Установить NaiveProxy       9)  Обновить Caddy
   2)  Статус + сертификат         10) Логи
   3)  Клиентский конфиг + QR      11) Удалить NaiveProxy
   4)  Пользователи                ──────────────────
   5)  Домены                      12) 🔒 SSH Hardening
   6)  Мониторинг + статистика     13) 🔄 Обновить систему
   7)  Настройка Telegram          14) ⬆️  Обновить скрипт
   8)  Перезапустить Caddy         15) 🎭 Обновить камуфляж
──────────────────────────────────────────────────────
```

### CLI команды:

```bash
sudo bash naiveproxy.sh install        # Полная установка
sudo bash naiveproxy.sh status         # Статус + TLS сертификат
sudo bash naiveproxy.sh config         # Конфиг + QR код
sudo bash naiveproxy.sh qr             # Только QR код
sudo bash naiveproxy.sh cert           # Только сертификат
sudo bash naiveproxy.sh users          # Управление пользователями
sudo bash naiveproxy.sh domains        # Управление доменами
sudo bash naiveproxy.sh monitor        # Мониторинг + статистика
sudo bash naiveproxy.sh restart        # Перезапустить Caddy
sudo bash naiveproxy.sh update         # Обновить Caddy
sudo bash naiveproxy.sh logs           # Логи в реальном времени
sudo bash naiveproxy.sh tg-stats       # Статистика в Telegram
sudo bash naiveproxy.sh ssh-hardening  # SSH Hardening
sudo bash naiveproxy.sh ssh-key        # Показать SSH приватный ключ
sudo bash naiveproxy.sh sysupdate      # Обновление системы
sudo bash naiveproxy.sh self-update    # Обновить скрипт с GitHub
sudo bash naiveproxy.sh camouflage     # Переустановить камуфляж
sudo bash naiveproxy.sh version        # Показать версию
sudo bash naiveproxy.sh remove         # Удалить всё
```

---

## 🔒 SSH Hardening

```bash
sudo bash naiveproxy.sh ssh-hardening
```

> 💡 **Можно пропустить** если SSH уже настроен. Нажми `n` при установке.

### 5 шагов:

**① Новый sudo-пользователь** — создаётся с паролем (или случайным)

**② ED25519 SSH-ключ + авто-сохранение**

Ключ автоматически сохраняется в `/etc/naiveproxy/ssh_private_key`.  
Скрипт выводит готовую команду для скачивания:

```bash
# Linux/macOS:
scp root@YOUR_IP:/etc/naiveproxy/ssh_private_key ~/.ssh/id_naiveproxy
chmod 600 ~/.ssh/id_naiveproxy

# Windows PowerShell:
scp root@YOUR_IP:/etc/naiveproxy/ssh_private_key $HOME\.ssh\id_naiveproxy

# Подключение:
ssh -i ~/.ssh/id_naiveproxy -p НОВЫЙ_ПОРТ user@YOUR_IP
```

Посмотреть ключ в любой момент:
```bash
sudo bash naiveproxy.sh ssh-key
```

**③ Смена SSH порта** — вручную или случайный (49000-65000)

**④ sshd_config**
```ini
PermitRootLogin        no
PasswordAuthentication no
MaxAuthTries           3
LoginGraceTime         30
X11Forwarding          no
```

**⑤ UFW + Fail2Ban** — новый порт открывается ДО закрытия старого

---

## 🛡️ Firewall

Скрипт настраивает многоуровневую защиту:

### UFW
```
Дефолт: DENY ALL INCOMING — блокируем всё входящее
Открыто: 80/tcp (ACME), 443/tcp, 443/udp, SSH порт
Заблокировано: MySQL(3306), Redis(6379), MongoDB(27017),
               Elasticsearch(9200), 8080, 8888...
Лимит: 80/tcp — защита от DDoS на ACME
```

### Fail2Ban — 3 уровня защиты

| Уровень | Триггер | Бан |
|---------|---------|-----|
| Брутфорс SSH | 3 неверных пароля | **7 дней** |
| DDoS SSH | 10 попыток за 1 минуту | **7 дней** |
| Рецидивист | Повторные нарушения | **30 дней** |

---

## 📱 QR код для подключения

После установки скрипт автоматически генерирует QR прямо в терминале:

```
█████████████████████████████████
█ ▄▄▄▄▄ █▀▄▀█▀▄▀ ▀█▄▀ █ ▄▄▄▄▄ █
█ █   █ █▄▄▀▀▄█▄▀▄█▀▀▀█ █   █ █
...
```

Отсканируй в **NekoBox** или **Shadowrocket** — подключение в один клик!

Показать QR в любой момент:
```bash
sudo bash naiveproxy.sh qr
```

---

## ⚠️ Критически важно — Caddyfile

**Именно это не даёт подключиться в большинстве случаев:**

```bash
# ❌ НЕПРАВИЛЬНО — клиенты не подключаются:
your-domain.com:443 {
  ...
}

# ✅ ПРАВИЛЬНО — :443 должен быть ПЕРВЫМ:
:443, your-domain.com {
  tls your@email.com
  forward_proxy {
    basic_auth user password
    hide_ip
    hide_via
    probe_resistance
  }
  file_server {
    root /var/www/html
  }
}
```

Скрипт генерирует правильный конфиг автоматически начиная с v3.7.0.

---

## 🤖 Telegram-бот

1. [@BotFather](https://t.me/BotFather) → `/newbot` → токен
2. [@userinfobot](https://t.me/userinfobot) → chat_id
3. Меню → **7) Настройка Telegram**

| Событие | Сообщение |
|---------|-----------|
| Установка | ✅ NaiveProxy запущен |
| Caddy упал | 🔴 Упал → автоперезапуск |
| SSH Hardening | 🔒 Порт: 52847 |
| Сертификат < 7 дней | ⚠️ Осталось 5 дней! |
| Статистика | 📊 Трафик · RAM · Диск · Сертификат |

---

## 📱 Клиентские приложения

### URI (вставить в любой клиент):
```
naive+https://USERNAME:PASSWORD@YOUR_DOMAIN:443
```

### JSON (naive-client Windows/Linux):
```json
{
  "listen": "socks://127.0.0.1:1080",
  "proxy": "https://USERNAME:PASSWORD@YOUR_DOMAIN:443",
  "log": "naive.log"
}
```

### Рекомендуемые клиенты:

| Клиент | Платформа | Способ добавить |
|--------|-----------|-----------------|
| [NekoBox](https://github.com/MatsuriDayo/NekoBoxForAndroid/releases) | Android | Сканировать QR / URI |
| [Shadowrocket](https://apps.apple.com/app/shadowrocket/id932747118) | iPhone | URI |
| [Hiddify](https://github.com/hiddify/hiddify-next/releases) | Windows / macOS | URI |
| [naive](https://github.com/klzgrad/naiveproxy/releases) | Windows / Linux | config.json |
| [sing-box](https://github.com/SagerNet/sing-box) | Все платформы | JSON конфиг |

> ⚠️ **v2rayNG не поддерживает NaiveProxy.** Используй NekoBox или Hiddify.

---

## 🎭 Страница-камуфляж

По умолчанию — IT-блог **DevStack**. Выглядит как реальный сайт для сканеров.

**Путь:** `/var/www/html/index.html`

```bash
# Заменить своей страницей:
scp my_site.html user@YOUR_IP:/var/www/html/index.html

# Восстановить DevStack:
sudo bash naiveproxy.sh camouflage
```

---

## 📁 Файловая структура

```
/usr/local/bin/caddy
/etc/caddy/Caddyfile                       (chmod 600)
/etc/naiveproxy/
├── naive.conf                             (chmod 600)
├── users.conf                             (chmod 600)
├── ssh_private_key                        ← SSH ключ (авто-сохранение)
├── ssh_public_key                         ← SSH публичный ключ
├── monitor.sh
├── .ssh_hardened
├── .sysupdate_done
└── backups/
/etc/fail2ban/jail.local                   ← 3 уровня защиты
/var/www/html/index.html                   ← камуфляжная страница
/var/log/caddy/access.log
/var/log/caddy/naive.log
```

---

## ❓ FAQ

<details>
<summary><b>Клиент не подключается</b></summary>

Проверь Caddyfile:
```bash
cat /etc/caddy/Caddyfile | grep ":443"
# Должно быть: :443, your-domain.com {
# НЕ: your-domain.com:443 {
```

Проверь ALPN:
```bash
openssl s_client -connect YOUR_DOMAIN:443 -alpn h2 2>/dev/null | grep "ALPN protocol"
# Должно быть: ALPN protocol: h2
```

</details>

<details>
<summary><b>Как скачать SSH ключ на компьютер</b></summary>

```bash
# Linux/macOS:
scp root@YOUR_IP:/etc/naiveproxy/ssh_private_key ~/.ssh/id_naiveproxy
chmod 600 ~/.ssh/id_naiveproxy

# Windows PowerShell:
scp root@YOUR_IP:/etc/naiveproxy/ssh_private_key $HOME\.ssh\id_naiveproxy

# Подключение:
ssh -i ~/.ssh/id_naiveproxy -p SSH_PORT user@YOUR_IP
```

</details>

<details>
<summary><b>Заблокировал себя после SSH hardening</b></summary>

Зайди через консоль хостинга (VNC/KVM):
```bash
ufw allow 22/tcp && systemctl restart sshd
```

</details>

<details>
<summary><b>Caddy не получает TLS сертификат</b></summary>

```bash
dig +short YOUR_DOMAIN        # должен вернуть IP сервера
ss -tlnp | grep :80           # порт 80 должен слушать Caddy
journalctl -u caddy -n 50 | grep -i "acme\|error\|cert"
```

</details>

<details>
<summary><b>Как проверить что IP изменился</b></summary>

```bash
# На сервере:
curl -x socks5://127.0.0.1:1080 https://ifconfig.me

# На Windows с запущенным naive.exe:
curl.exe --proxy socks5://127.0.0.1:1080 https://ifconfig.me
```

</details>

---

## 📊 Сравнение

| Функция | **NaiveProxy Manager** | x-ui / 3x-ui | Marzban |
|---------|:---:|:---:|:---:|
| Без Docker | ✅ | ❌ | ❌ |
| SSH Hardening | ✅ | ❌ | ❌ |
| Авто-сохранение SSH ключа | ✅ | ❌ | ❌ |
| QR код при установке | ✅ | ❌ | ❌ |
| Fail2Ban 3 уровня | ✅ | ❌ | ❌ |
| UFW deny all + сканеры | ✅ | ❌ | ❌ |
| Обновление системы | ✅ | ❌ | ❌ |
| Self-Update скрипта | ✅ | ❌ | ❌ |
| Страница-камуфляж | ✅ | ❌ | ❌ |
| Проверка сертификата | ✅ | ❌ | ❌ |
| Правильный Caddyfile | ✅ v3.7+ | — | — |
| Telegram алерты | ✅ | ✅ | ✅ |
| ShellCheck passing | ✅ | — | — |

---

## 📜 Changelog

<details>
<summary><b>v3.8.0</b> — Security & UX ← ТЕКУЩАЯ</summary>

- ✨ Авто-сохранение SSH ключа в `/etc/naiveproxy/ssh_private_key`
- ✨ QR код для подключения прямо в терминале
- ✨ Команда для скачивания ключа (scp)
- 🛡️ UFW: `deny all incoming` + блокировка портов сканеров
- 🛡️ Fail2Ban 3 уровня: брутфорс(7д) / DDoS(7д) / рецидив(30д)
- 🆕 CLI: `qr`, `ssh-key`

</details>

<details>
<summary><b>v3.7.0</b> — Critical Caddyfile Fix</summary>

- 🔴 Критический фикс: `:443, domain` вместо `domain:443`
- ✅ Подтверждено: NekoBox Android + naive.exe Windows работают

</details>

<details>
<summary><b>v3.6.0</b> — Critical Build Fix</summary>

- 🔴 build_caddy: git clone `klzgrad/forwardproxy@naive` напрямую
- 🔴 Автоопределение совместимой версии Caddy из go.mod

</details>

<details>
<summary><b>v3.5.0</b> — Security Audit</summary>

- 🔒 grep -vF вместо sed, --data-urlencode, trap cleanup

</details>

<details>
<summary><b>v3.0-3.4</b> — Core Features</summary>

- Обновление системы, SSH Hardening, Self-update, Домены, Камуфляж

</details>

---

## 📄 Лицензия

MIT © [ivanstudiya-cpu](https://github.com/ivanstudiya-cpu)

---

<div align="center">

**Если скрипт помог — поставь ⭐ звезду**

[![GitHub stars](https://img.shields.io/github/stars/ivanstudiya-cpu/naiveproxy?style=for-the-badge&color=D4A017)](https://github.com/ivanstudiya-cpu/naiveproxy/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/ivanstudiya-cpu/naiveproxy?style=for-the-badge&color=58A6FF)](https://github.com/ivanstudiya-cpu/naiveproxy/network)

*NaiveProxy Manager · Caddy 2 · klzgrad/forwardproxy@naive · Ubuntu*

</div>
