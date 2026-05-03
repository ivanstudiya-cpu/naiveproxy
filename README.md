<div align="center">

🌐 **Язык / Language:** [🇷🇺 Русский](README.md) | [🇬🇧 English](README_EN.md)

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

**Профессиональный менеджер приватного прокси-сервера**
Caddy 2 · NaiveProxy · Telegram Bot · DNS блокировка · Диагностика · SSH Hardening

---

[![Version](https://img.shields.io/badge/version-4.2.1-D4A017?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ivanstudiya-cpu/naiveproxy/releases)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-3FB950?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.shellcheck.net)
[![Bash](https://img.shields.io/badge/Bash-5.0+-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Caddy](https://img.shields.io/badge/Caddy-auto-00ADD8?style=for-the-badge&logo=caddy&logoColor=white)](https://caddyserver.com)
[![License](https://img.shields.io/badge/License-MIT-58A6FF?style=for-the-badge)](LICENSE)

---

[**Быстрый старт**](#-быстрый-старт) • [**Возможности**](#-возможности) • [**Telegram бот**](#-telegram-бот) • [**DNS блокировка**](#-dns-блокировка-рекламы) • [**Диагностика**](#-диагностика) • [**FAQ**](#-faq)

</div>

---

<div align="center">

🔔 **Обновления выходят раз в месяц**

[![Telegram](https://img.shields.io/badge/Telegram-Канал-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/+XVSkY6blCTY0ZDU6)
[![Website](https://img.shields.io/badge/Сайт-ivan--it.net-D4A017?style=for-the-badge&logo=googlechrome&logoColor=white)](https://ivan-it.net)
[![GitHub](https://img.shields.io/badge/GitHub-ivanstudiya--cpu-3FB950?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ivanstudiya-cpu/naiveproxy)

</div>

---

## 🤔 Что это

**NaiveProxy** маскирует трафик под браузер Chrome используя настоящий Chromium network stack. DPI и цензоры видят легитимный HTTPS/2 — и пропускают.

**NaiveProxy Manager** — один bash-скрипт который превращает голый VPS в полноценный защищённый прокси-сервер с блокировкой рекламы и Telegram управлением.

```
┌─────────────┐     ┌──────────────┐     ┌───────────────────────────┐     ┌──────────┐
│  Твой       │     │  Цензор/DPI  │     │   Твой VPS                │     │          │
│  телефон    │────▶│              │────▶│   Caddy + NaiveProxy      │────▶│ Интернет │
│  ноутбук    │     │  Видит Chrome│     │   unbound DNS блокировка  │     │          │
└─────────────┘     │  HTTPS/2 ✓   │     │   probe_resistance        │     └──────────┘
 naive-client        └──────────────┘     └───────────────────────────┘
 Chromium stack       Пропускает           реклама заблокирована 🚫
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
- **Fail2Ban 3 уровня** — брутфорс(7д) / DDoS(7д) / рецидив(30д)
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

### 🚫 DNS блокировка рекламы
- **~1.5 млн доменов** — реклама, трекеры, малварь
- **unbound** — быстрый локальный резолвер
- **DNS-over-TLS** — зашифрованные запросы
- **3 источника blocklists** — StevenBlack, AdAway, Hagezi
- **Whitelist** — разрешить нужные домены
- **Автообновление** — свежие списки по расписанию

### 🤖 Telegram бот
- **16 команд** — полное управление из Telegram
- **Мультиадмины** — несколько управляющих
- **QR код картинкой** — прямо в чат
- **/adduser /deluser** — управление пользователями
- **/diagnose** — диагностика из Telegram
- **Системный сервис** — работает 24/7

### 🔍 Диагностика
- **7 блоков проверок** — Caddy, TLS, сеть, DNS, firewall, ресурсы, логи
- **Цветной отчёт** — ✅ / ⚠️ / ❌ по каждому пункту
- **Отправка в Telegram** — одним нажатием

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
   NaiveProxy Manager v4.2.0  [РУС]
   Статус: ● работает  │  Домен: proxy.example.com
   Telegram: подключён  │  Юзеров: 3  │  SSH: 52847
──────────────────────────────────────────────────────
   1)  Установить NaiveProxy       10) Логи
   2)  Статус + сертификат         11) Удалить NaiveProxy
   3)  Клиентский конфиг + QR      16) 🔍 Диагностика
   4)  Пользователи                17) 🚫 DNS блокировщик
   5)  Домены                      ──────────────────
   6)  Мониторинг + статистика     12) 🔒 SSH Hardening
   7)  Настройка Telegram + Бот    13) 🔄 Обновить систему
   8)  Перезапустить Caddy         14) ⬆️  Обновить скрипт
   9)  Обновить Caddy              15) 🎭 Обновить камуфляж
──────────────────────────────────────────────────────
```

### Все CLI команды:

```bash
sudo bash naiveproxy.sh install        # Полная установка
sudo bash naiveproxy.sh status         # Статус + сертификат
sudo bash naiveproxy.sh config         # Конфиг + QR код
sudo bash naiveproxy.sh qr             # Только QR код
sudo bash naiveproxy.sh cert           # Только сертификат
sudo bash naiveproxy.sh users          # Пользователи
sudo bash naiveproxy.sh domains        # Домены
sudo bash naiveproxy.sh monitor        # Мониторинг
sudo bash naiveproxy.sh restart        # Перезапустить Caddy
sudo bash naiveproxy.sh update         # Обновить Caddy
sudo bash naiveproxy.sh logs           # Логи
sudo bash naiveproxy.sh tg-stats       # Статистика в Telegram
sudo bash naiveproxy.sh bot            # Запустить Telegram бот
sudo bash naiveproxy.sh bot-install    # Бот как системный сервис
sudo bash naiveproxy.sh dns            # DNS блокировщик (меню)
sudo bash naiveproxy.sh dns-install    # Установить DNS блокировщик
sudo bash naiveproxy.sh dns-update     # Обновить blocklists
sudo bash naiveproxy.sh dns-status     # Статус DNS блокировщика
sudo bash naiveproxy.sh diagnose       # Диагностика системы
sudo bash naiveproxy.sh ssh-hardening  # SSH Hardening
sudo bash naiveproxy.sh ssh-key        # Показать SSH ключ
sudo bash naiveproxy.sh sysupdate      # Обновить систему
sudo bash naiveproxy.sh self-update    # Обновить скрипт
sudo bash naiveproxy.sh camouflage     # Переустановить камуфляж
sudo bash naiveproxy.sh version        # Версия
sudo bash naiveproxy.sh remove         # Удалить всё
```

---

## 🤖 Telegram Бот

Полноценное управление сервером прямо из Telegram.

### Запуск:

```bash
# Тест (ручной):
sudo bash naiveproxy.sh bot

# Как системный сервис (автозапуск):
sudo bash naiveproxy.sh bot-install

# Остановить сервис:
systemctl stop naiveproxy-bot
```

### Все команды бота:

| Команда | Действие |
|---------|----------|
| `/help` | Список всех команд |
| `/status` | Статус + RAM + диск + сертификат |
| `/stats` | Полная статистика |
| `/diagnose` | Диагностика 7 блоков |
| `/logs` | Последние 20 строк логов |
| `/cert` | Статус TLS сертификата 🟢/🟡/🔴 |
| `/users` | Список пользователей |
| `/adduser login pass` | Добавить пользователя |
| `/deluser login` | Удалить пользователя |
| `/qr login` | QR код картинкой в чат |
| `/restart` | Перезапустить Caddy |
| `/update` | Обновить Caddy |
| `/selfupdate` | Проверить обновления скрипта |
| `/admins` | Список администраторов |
| `/addadmin ID` | Добавить администратора |
| `/deladmin ID` | Удалить администратора |

### Мультиадмины:

```
/addadmin 987654321   ← добавить второго админа
/admins               ← посмотреть список
```

Все команды защищены — чужой получит `⛔ Доступ запрещён`.

---

## 🚫 DNS блокировка рекламы

Блокирует рекламу и трекеры на уровне DNS — работает для **всех устройств** подключённых через прокси.

```bash
sudo bash naiveproxy.sh dns-install    # Установить
sudo bash naiveproxy.sh dns-update     # Обновить blocklists
sudo bash naiveproxy.sh dns-status     # Статус и тест
sudo bash naiveproxy.sh dns            # Меню
```

### Как работает:

```
Телефон → NaiveProxy → unbound (127.0.0.1:5335)
                            ↓
               ads.google.com → REFUSE ❌ (заблокирован)
               youtube.com → Cloudflare DoT ✅ (работает)
```

### Источники (~1.5 млн доменов):

| Источник | Что блокирует |
|----------|--------------|
| StevenBlack/hosts | Реклама + малварь |
| AdAway | Мобильная реклама |
| Hagezi Pro | Агрессивная блокировка |

### Если что-то сломалось — whitelist:

```bash
sudo bash naiveproxy.sh dns
# → 4) Разрешить домен
```

---

## 🔍 Диагностика

```bash
sudo bash naiveproxy.sh diagnose
```

```
[1/7] Caddy          ✅ запущен · ✅ naive padding · ✅ модуль
[2/7] Конфигурация   ✅ :443,domain · ✅ пользователи · ✅ валид
[3/7] TLS и сеть     ✅ DNS · ✅ порты · ✅ ALPN h2 · ✅ сертификат
[4/7] Firewall       ✅ UFW · ✅ Fail2Ban активен
[5/7] Ресурсы        ✅ RAM 40% · ✅ Диск 37% · ✅ CPU 6%
[6/7] Логи           ✅ нет ошибок · ℹ️ 47 CONNECT туннелей
[7/7] Версия         ✅ актуальна · ✅ SSH hardening выполнен

📊 ИТОГ: ✅ 18  ⚠️ 0  ❌ 0
🎉 Всё работает отлично!
```

---

## ⚠️ Критически важно — Caddyfile

```bash
# ❌ НЕПРАВИЛЬНО — клиенты не подключаются:
your-domain.com:443 { ... }

# ✅ ПРАВИЛЬНО — :443 должен быть ПЕРВЫМ:
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

> 💡 **Можно пропустить** нажав `n` при установке.

**5 шагов:** новый sudo-пользователь → ED25519 ключ (авто-сохранение) → смена порта → sshd_config → UFW + Fail2Ban

```bash
# Скачать SSH ключ:
scp root@YOUR_IP:/etc/naiveproxy/ssh_private_key ~/.ssh/id_naiveproxy
chmod 600 ~/.ssh/id_naiveproxy

# Показать ключ:
sudo bash naiveproxy.sh ssh-key
```

**Fail2Ban 3 уровня:**

| Уровень | Триггер | Бан |
|---------|---------|-----|
| Брутфорс | 3 неверных пароля | **7 дней** |
| DDoS | 10 попыток за 1 мин | **7 дней** |
| Рецидив | Повторные нарушения | **30 дней** |

---

## 📱 Клиентские приложения

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

| Клиент | Платформа | Способ |
|--------|-----------|--------|
| [NekoBox](https://github.com/MatsuriDayo/NekoBoxForAndroid/releases) | Android | QR / URI |
| [Shadowrocket](https://apps.apple.com/app/shadowrocket/id932747118) | iPhone | URI ($2.99) |
| [Hiddify](https://github.com/hiddify/hiddify-next/releases) | Windows / macOS | URI |
| [naive](https://github.com/klzgrad/naiveproxy/releases) | Windows / Linux | config.json |

> ⚠️ **v2rayNG не поддерживает NaiveProxy.** Используй NekoBox или Hiddify.

---

## 📁 Файловая структура

```
/usr/local/bin/caddy
/etc/caddy/Caddyfile                       (chmod 600)
/etc/naiveproxy/
├── naive.conf                             (chmod 600)
├── users.conf                             (chmod 600)
├── ssh_private_key                        ← SSH ключ
├── ssh_public_key
├── dns_stats                              ← статистика DNS
├── monitor.sh
├── .ssh_hardened
├── .sysupdate_done
└── backups/
/etc/unbound/
├── unbound.conf.d/naiveproxy-dns.conf     ← DNS конфиг
├── blocklist.conf                         ← ~1.5М доменов
└── whitelist.txt                          ← разрешённые домены
/etc/fail2ban/jail.local
/etc/systemd/system/
├── caddy.service
└── naiveproxy-bot.service                 ← Telegram бот
/var/www/html/index.html                   ← камуфляж
/var/log/caddy/access.log
/var/log/caddy/naive.log
```

---

## ❓ FAQ

<details>
<summary><b>Клиент не подключается</b></summary>

```bash
# Запусти диагностику:
sudo bash naiveproxy.sh diagnose

# Проверь Caddyfile:
cat /etc/caddy/Caddyfile | grep ":443"
# Должно быть: :443, your-domain.com {

# Проверь ALPN:
openssl s_client -connect YOUR_DOMAIN:443 -alpn h2 2>/dev/null | grep "ALPN protocol"
# Должно быть: ALPN protocol: h2
```

</details>

<details>
<summary><b>DNS блокировка ломает какой-то сайт</b></summary>

```bash
sudo bash naiveproxy.sh dns
# → 4) Разрешить домен → введи домен
```

</details>

<details>
<summary><b>Как скачать SSH ключ</b></summary>

```bash
scp root@YOUR_IP:/etc/naiveproxy/ssh_private_key ~/.ssh/id_naiveproxy
chmod 600 ~/.ssh/id_naiveproxy
ssh -i ~/.ssh/id_naiveproxy -p NEW_PORT user@YOUR_IP
```

</details>

<details>
<summary><b>Заблокировал себя после SSH hardening</b></summary>

```bash
# Зайди через VNC/KVM консоль хостинга:
ufw allow 22/tcp && systemctl restart sshd
```

</details>

<details>
<summary><b>Telegram бот не отвечает</b></summary>

```bash
systemctl status naiveproxy-bot
journalctl -u naiveproxy-bot -n 20 --no-pager
# Перезапустить:
systemctl restart naiveproxy-bot
```

</details>

---

## 📊 Сравнение

| Функция | **NaiveProxy Manager** | x-ui / 3x-ui | Marzban |
|---------|:---:|:---:|:---:|
| Без Docker | ✅ | ❌ | ❌ |
| SSH Hardening | ✅ | ❌ | ❌ |
| SSH ключ авто-сохранение | ✅ | ❌ | ❌ |
| QR код | ✅ | ❌ | ❌ |
| **DNS блокировка рекламы** | ✅ | ❌ | ❌ |
| **Telegram бот с командами** | ✅ 16 команд | ⚠️ базовый | ⚠️ базовый |
| Диагностика системы | ✅ | ❌ | ❌ |
| Fail2Ban 3 уровня | ✅ | ❌ | ❌ |
| Страница-камуфляж | ✅ | ❌ | ❌ |
| Self-Update | ✅ | ❌ | ❌ |
| Правильный Caddyfile | ✅ v3.7+ | — | — |
| ShellCheck passing | ✅ | — | — |

---

## 📜 Changelog

<details>
<summary><b>v4.2.0</b> — DNS Ad Blocker ← ТЕКУЩАЯ</summary>

- ✨ DNS блокировка рекламы через unbound (~1.5М доменов)
- ✨ DNS-over-TLS (Cloudflare + Google)
- ✨ Whitelist для разрешения заблокированных доменов
- ✨ Меню → 17) DNS блокировщик
- 🆕 CLI: `dns`, `dns-install`, `dns-update`, `dns-status`

</details>

<details>
<summary><b>v4.1.0</b> — Security Audit</summary>

- 🔒 Валидация from_id в боте (только числа)
- 🔒 Лимит длины команды 256 + санитизация args
- 🔒 Строгая валидация /addadmin (5-15 цифр)
- 🔒 Защита от переполнения offset в polling
- 🐛 Исправлена переменная DIM (unbound variable)

</details>

<details>
<summary><b>v4.0.0</b> — Telegram Bot</summary>

- ✨ Полноценный Telegram бот с 16 командами
- ✨ Мультиадмины (/addadmin, /deladmin)
- ✨ QR код картинкой в Telegram
- ✨ Системный сервис naiveproxy-bot
- 🆕 CLI: `bot`, `bot-install`

</details>

<details>
<summary><b>v3.9.0</b> — Diagnostics</summary>

- ✨ Полная диагностика системы — 7 блоков, 18+ проверок
- ✨ Отправка отчёта в Telegram
- 🆕 CLI: `diagnose`

</details>

<details>
<summary><b>v3.8.0</b> — Security & UX</summary>

- ✨ SSH ключ авто-сохранение + scp команда
- ✨ QR код в терминале
- 🛡️ UFW deny all + блокировка портов сканеров
- 🛡️ Fail2Ban 3 уровня

</details>

<details>
<summary><b>v3.7.0</b> — Critical Fix</summary>

- 🔴 Критический фикс Caddyfile: `:443, domain` вместо `domain:443`

</details>

<details>
<summary><b>v3.0–3.6</b> — Core</summary>

- Обновление системы, SSH Hardening, Self-update, Домены, Камуфляж, Build fix

</details>

---

## 📄 Лицензия

MIT © [ivanstudiya-cpu](https://github.com/ivanstudiya-cpu)

---

<div align="center">

**Если скрипт помог — поставь ⭐ звезду**

[![GitHub stars](https://img.shields.io/github/stars/ivanstudiya-cpu/naiveproxy?style=for-the-badge&color=D4A017)](https://github.com/ivanstudiya-cpu/naiveproxy/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/ivanstudiya-cpu/naiveproxy?style=for-the-badge&color=58A6FF)](https://github.com/ivanstudiya-cpu/naiveproxy/network)

📱 [Telegram канал](https://t.me/+XVSkY6blCTY0ZDU6) · 🌐 [ivan-it.net](https://ivan-it.net) · 💻 [GitHub](https://github.com/ivanstudiya-cpu/naiveproxy)

*NaiveProxy Manager · by Иван Юрьевич · Обновления раз в месяц*

</div>
