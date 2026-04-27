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
Caddy 2 · NaiveProxy · Let's Encrypt · Telegram · SSH Hardening · Self-Update

---

[![Version](https://img.shields.io/badge/version-3.5.0-D4A017?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ivanstudiya-cpu/naiveproxy/releases)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-3FB950?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.shellcheck.net)
[![Bash](https://img.shields.io/badge/Bash-5.0+-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Caddy](https://img.shields.io/badge/Caddy-2.x-00ADD8?style=for-the-badge&logo=caddy&logoColor=white)](https://caddyserver.com)
[![License](https://img.shields.io/badge/License-MIT-58A6FF?style=for-the-badge)](LICENSE)

---

</div>

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

Или скачать вручную:

```bash
wget -O naiveproxy.sh https://raw.githubusercontent.com/ivanstudiya-cpu/naiveproxy/main/naiveproxy.sh
chmod +x naiveproxy.sh && sudo bash naiveproxy.sh
```

### Что происходит при первом запуске:

```
[1/5] 🔄  Обновление системы
         apt upgrade + unattended-upgrades (security patches ежедневно)

[2/5] 🔒  SSH Hardening
         ED25519 ключ · новый sudo-пользователь · смена порта · Fail2Ban

[3/5] 📦  Сборка Caddy
         xcaddy + klzgrad/forwardproxy@naive  ~5-10 минут

[4/5] ⚙️   Настройка
         Caddyfile · systemd · UFW · TCP BBR · Telegram (опц.)

[5/5] ✅  Готово
         URI + JSON конфиги для всех клиентов
```

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
   NaiveProxy Manager v3.5.0
   Статус: ● работает  │  Домен: proxy.example.com
   Telegram: подключён  │  Юзеров: 3  │  SSH: 52847
──────────────────────────────────────────────────────
   1)  Установить NaiveProxy       9)  Обновить Caddy
   2)  Статус + сертификат         10) Логи
   3)  Клиентский конфиг           11) Удалить NaiveProxy
   4)  Пользователи                ──────────────────
   5)  Домены                      12) 🔒 SSH Hardening
   6)  Мониторинг + статистика     13) 🔄 Обновить систему
   7)  Настройка Telegram          14) ⬆️  Обновить скрипт
   8)  Перезапустить Caddy         15) 🎭 Обновить камуфляж
──────────────────────────────────────────────────────
```

### Все CLI команды:

```bash
sudo bash naiveproxy.sh install        # Полная установка
sudo bash naiveproxy.sh status         # Статус + TLS сертификат
sudo bash naiveproxy.sh config         # Клиентский конфиг
sudo bash naiveproxy.sh cert           # Только сертификат
sudo bash naiveproxy.sh users          # Управление пользователями
sudo bash naiveproxy.sh domains        # Управление доменами
sudo bash naiveproxy.sh monitor        # Мониторинг + статистика
sudo bash naiveproxy.sh restart        # Перезапустить Caddy
sudo bash naiveproxy.sh update         # Обновить Caddy
sudo bash naiveproxy.sh logs           # Логи в реальном времени
sudo bash naiveproxy.sh tg-stats       # Статистика в Telegram
sudo bash naiveproxy.sh ssh-hardening  # SSH Hardening
sudo bash naiveproxy.sh sysupdate      # Обновление системы
sudo bash naiveproxy.sh self-update    # Обновить скрипт с GitHub
sudo bash naiveproxy.sh camouflage     # Переустановить страницу-камуфляж
sudo bash naiveproxy.sh version        # Показать версию
sudo bash naiveproxy.sh remove         # Удалить всё
```

---

## ✨ Все возможности

<table>
<tr>
<td width="50%" valign="top">

### 🔐 Безопасность сервера
- SSH Hardening — ED25519 ключ, смена порта, блокировка root
- Fail2Ban — 3 попытки → бан на 24 часа
- UFW — только нужные порты, автовключение
- unattended-upgrades — security-патчи ежедневно
- probe_resistance — выглядит как обычный сайт
- 🎭 **Страница-камуфляж** — IT-блог DevStack

### 📡 Прокси
- Автоматический TLS — Let's Encrypt через Caddy
- Мультипользователь — добавление без рестарта
- Несколько доменов — на одном сервере
- HTTP/3 (QUIC) — 443/udp автоматически
- TCP BBR — опциональное ускорение

</td>
<td width="50%" valign="top">

### 🤖 Автоматизация
- Telegram-бот — алерты + статистика по команде
- Watchdog — cron каждые 5 минут, автоперезапуск
- Автообновление Caddy — каждое воскресенье 3:00
- ⬆️ **Self-update** — обновление скрипта с GitHub
- Проверка сертификата — срок + алерт при < 7 дней

### 🛡️ Качество кода
- `set -euo pipefail` — строгий режим
- SHA256-верификация Go бинарника
- `grep -vF` вместо `sed` — нет regex injection
- `--data-urlencode` для Telegram — нет инъекций
- `trap` для cleanup временных файлов
- Валидация всех входных данных
- ShellCheck passing — 0 предупреждений
- Бэкап перед каждым изменением

</td>
</tr>
</table>

---

## 🔒 SSH Hardening

```bash
sudo bash naiveproxy.sh ssh-hardening
```

Запускается автоматически при первой установке. Делает 5 шагов:

**① Новый sudo-пользователь**
```
Имя: ivan
✓ Создан с правами sudo
✓ Пароль: Xk9mP2qR7nL4vT8w  ← СОХРАНИ!
```

**② ED25519 SSH-ключ**
Приватный ключ выводится в терминал — нужно сохранить:
```bash
echo "ВСТАВЬ_КЛЮЧ" > ~/.ssh/id_naiveproxy && chmod 600 ~/.ssh/id_naiveproxy
ssh -i ~/.ssh/id_naiveproxy -p НОВЫЙ_ПОРТ ivan@YOUR_IP
```

**③ Смена SSH порта**
```
1) Ввести вручную
2) Случайный (49000-65000) ← рекомендуется
0) Оставить 22
```
Случайный порт проверяется через `ss -tlnp` — не назначается занятый.

**④ sshd_config**
```ini
PermitRootLogin        no
PasswordAuthentication no
PubkeyAuthentication   yes
MaxAuthTries           3
LoginGraceTime         30
X11Forwarding          no
PermitEmptyPasswords   no
```
Перед применением: `sshd -t` → откат по бэкапу при ошибке.

**⑤ UFW + Fail2Ban**
```
✓ Новый порт открыт в UFW ДО закрытия старого
✓ Fail2Ban: 3 попытки → бан 24 часа
```

---

## 🤖 Telegram-бот

Настройка за 2 минуты:
1. [@BotFather](https://t.me/BotFather) → `/newbot` → токен
2. [@userinfobot](https://t.me/userinfobot) → chat_id
3. Меню → **7) Настройка Telegram**

**Все уведомления:**

| Событие | Сообщение |
|---------|-----------|
| Установка | ✅ NaiveProxy запущен |
| Caddy упал | 🔴 Упал → автоперезапуск |
| Перезапуск ок | ✅ Перезапущен |
| Перезапуск не помог | ❌ Нужно вмешательство |
| Caddy обновлён | 🔄 v2.8 → v2.9 |
| Скрипт обновлён | ⬆️ v3.4 → v3.5 |
| SSH Hardening | 🔒 Порт: 52847 |
| Обновление системы | 🔄 Обновлено |
| Новый пользователь | 👤 Добавлен alice |
| Удалён пользователь | 🗑 Удалён bob |
| Сертификат < 7 дней | ⚠️ Осталось 5 дней! |
| Статистика | 📊 Полный отчёт |

**Пример статистики:**
```
📊 Статистика NaiveProxy

🌐 Домен: proxy.example.com
📡 Статус: 🟢 Работает
🕐 Запущен: 2026-04-21 03:00
📦 Caddy: v2.9.1
👥 Пользователей: 3

📈 Трафик (с ребута):
⬇️  Входящий:  38.4G
⬆️  Исходящий: 12.1G

🖥 Сервер: vps-01
💾 RAM: 412M/1.0G
💿 Диск: 9.2G/25G (37%)

🔐 Сертификат:
📅 Истекает: Jul 22 2026 GMT
⏳ Осталось: 90 дней
```

---

## 🔐 TLS Сертификат

Caddy получает и обновляет сертификат **автоматически** через Let's Encrypt. За 30 дней до истечения — автообновление.

```bash
sudo bash naiveproxy.sh cert
```

```
  TLS Сертификат:
  Домен:     proxy.example.com
  Истекает:  Jul 22 01:28:35 2026 GMT
  Осталось:  90 дней                    ← 🟢
  Выдан:     Let's Encrypt
```

| Дней | Цвет | Действие |
|------|------|----------|
| > 30 | 🟢 Зелёный | Всё хорошо |
| 7–30 | 🟡 Жёлтый | Предупреждение |
| < 7  | 🔴 Красный | Алерт в Telegram |

---

## ⬆️ Self-Update

```bash
sudo bash naiveproxy.sh self-update
```

При запуске меню — тихая фоновая проверка GitHub:
```
  ⬆  Доступно обновление: v3.5.0 → v3.6.0
     Меню → 14) Обновить скрипт
```

Процесс обновления:
1. Проверяет версию через GitHub API
2. Скачивает новый скрипт
3. **Проверяет синтаксис** (`bash -n`) — не установит сломанную версию
4. Создаёт бэкап: `naiveproxy.sh.v3.5.0.bak`
5. Устанавливает и перезапускается

---

## 🎭 Страница-камуфляж

При установке Caddy автоматически поднимает **IT-блог "DevStack"** — выглядит как настоящий технический сайт:

- 📰 5 статей про Linux, Caddy, SSH, UFW, systemd
- 📊 Статистика блога (47 статей, 12k читателей)
- 💻 Виджет терминала с uptime в реальном времени
- 🏷️ Облако тегов: linux, security, caddy, ssh...
- 🌙 Тёмная тема с золотыми акцентами

Сканеры и DPI видят обычный технический блог.

```bash
sudo bash naiveproxy.sh camouflage    # Переустановить страницу
```

---

## 👥 Мультипользователь

```bash
sudo bash naiveproxy.sh users
```

```
  1) Список пользователей
  2) Добавить       ← caddy reload, сессии не прерываются
  3) Удалить
  4) Сменить пароль
```

Каждый пользователь — отдельный URI:
```
naive+https://alice:pass1@proxy.example.com:443
naive+https://bob:pass2@proxy.example.com:443
```

---

## 🌐 Несколько доменов

```bash
sudo bash naiveproxy.sh domains
```

Добавляй любое количество доменов — Caddy получит TLS для каждого. Все пользователи работают на всех доменах.

---

## 📱 Клиентские приложения

### URI для вставки в клиент:
```
naive+https://USERNAME:PASSWORD@YOUR_DOMAIN:443
```

### JSON (naive-client):
```json
{
  "listen": "socks://127.0.0.1:1080",
  "proxy": "https://USERNAME:PASSWORD@YOUR_DOMAIN:443"
}
```

### JSON (sing-box outbound):
```json
{
  "type": "http",
  "tag": "naiveproxy-out",
  "server": "YOUR_DOMAIN",
  "server_port": 443,
  "username": "USERNAME",
  "password": "PASSWORD",
  "tls": { "enabled": true, "server_name": "YOUR_DOMAIN" }
}
```

### Рекомендуемые клиенты:

| Клиент | Платформа | Примечание |
|--------|-----------|------------|
| [NekoBox](https://github.com/MatsuriDayo/NekoBoxForAndroid/releases) | Android | APK с GitHub |
| [Hiddify](https://github.com/hiddify/hiddify-next/releases) | Android / iOS / Windows / macOS | Рекомендуется |
| [sing-box](https://github.com/SagerNet/sing-box) | Все платформы | Универсальный |
| [v2rayN](https://github.com/2dust/v2rayN/releases) | Windows | + naive.exe |
| [naive](https://github.com/klzgrad/naiveproxy/releases) | Linux CLI | Официальный |

> ⚠️ **v2rayNG не поддерживает NaiveProxy.** Используй NekoBox или Hiddify.

### Проверить без клиента:
```bash
curl -v --proxy "https://USER:PASS@YOUR_DOMAIN:443" https://ifconfig.me
```

---

## 📁 Файловая структура

```
/usr/local/bin/caddy                       ← бинарник
/etc/caddy/Caddyfile                       ← конфиг (chmod 600)
/etc/naiveproxy/
├── naive.conf                             ← домен, email, TG (chmod 600)
├── users.conf                             ← user:pass (chmod 600)
├── monitor.sh                             ← watchdog
├── .ssh_hardened                          ← маркер SSH
├── .sysupdate_done                        ← маркер обновления
└── backups/Caddyfile.YYYYMMDD_HHMMSS      ← бэкапы
/etc/fail2ban/jail.local
/etc/apt/apt.conf.d/50unattended-upgrades
/var/www/html/index.html                   ← камуфляжная страница
/var/log/caddy/access.log
/var/log/caddy/naive.log
/etc/systemd/system/caddy.service
/usr/local/bin/naiveproxy.sh               ← скрипт (для cron)
```

---

## 🛡️ Модель безопасности

```
Сервер:
  ✓ UFW: whitelist — только 80, 443 (tcp+udp), SSH порт
  ✓ SSH: только ключ · root запрещён · нестандартный порт
  ✓ Fail2Ban: автобан брутфорса на 24 часа
  ✓ unattended-upgrades: security-патчи ежедневно

Прокси невидим:
  ✓ probe_resistance: выглядит как обычный веб-сайт
  ✓ Камуфляжная страница: IT-блог DevStack
  ✓ TLS fingerprint = Chrome (Chromium network stack)
  ✓ HTTP/2 CONNECT: неотличимо от браузерного трафика
  ✓ Let's Encrypt: валидный сертификат

Код:
  ✓ set -euo pipefail
  ✓ SHA256 верификация Go после загрузки
  ✓ grep -vF вместо sed для пользователей (нет regex injection)
  ✓ --data-urlencode для Telegram (нет HTML injection)
  ✓ trap cleanup временных файлов
  ✓ Проверка владельца конфига перед source
  ✓ Валидация домена, логина, порта, пароля
  ✓ Новый SSH порт открывается ДО закрытия старого
  ✓ sshd -t перед перезапуском → откат по бэкапу
  ✓ ShellCheck 0 предупреждений
```

---

## 📊 Сравнение

| Функция | **NaiveProxy Manager** | x-ui / 3x-ui | Marzban |
|---------|:---:|:---:|:---:|
| Без Docker | ✅ | ❌ | ❌ |
| SSH Hardening | ✅ | ❌ | ❌ |
| Обновление системы | ✅ | ❌ | ❌ |
| Self-Update скрипта | ✅ | ❌ | ❌ |
| Страница-камуфляж | ✅ | ❌ | ❌ |
| Проверка сертификата | ✅ | ❌ | ❌ |
| Несколько доменов | ✅ | ✅ | ✅ |
| Watchdog автоперезапуск | ✅ | ❌ | ❌ |
| SHA256 верификация | ✅ | ❌ | ❌ |
| ShellCheck passing | ✅ | — | — |
| probe_resistance | ✅ | ❌ | ❌ |
| Telegram алерты | ✅ | ✅ | ✅ |

---

## ❓ FAQ

<details>
<summary><b>Сборка Caddy занимает 10+ минут</b></summary>

Нормально — xcaddy компилирует Go-код с нуля. На 1 vCPU до 10-15 минут. Не прерывай процесс, он завершится.

</details>

<details>
<summary><b>Заблокировал себя после SSH hardening</b></summary>

Зайди через консоль хостинга (VNC/KVM/Serial):
```bash
ufw allow 22/tcp
systemctl restart sshd
cat /etc/ssh/sshd_config | grep Port
```

</details>

<details>
<summary><b>Caddy не получает TLS сертификат</b></summary>

Три вещи:
```bash
dig +short YOUR_DOMAIN        # должен вернуть IP сервера
ss -tlnp | grep :80           # порт 80 должен слушать Caddy
journalctl -u caddy -n 50 | grep -i "acme\|error\|cert"
```

</details>

<details>
<summary><b>v2rayNG выдаёт ошибку</b></summary>

v2rayNG не поддерживает NaiveProxy — это разные протоколы. Используй **NekoBox** (Android) или **Hiddify** (все платформы).

</details>

<details>
<summary><b>Как добавить пользователя без разрыва соединений</b></summary>

```bash
sudo bash naiveproxy.sh users  # → 2) Добавить
```
Используется `caddy reload` — активные сессии не прерываются.

</details>

<details>
<summary><b>Где хранятся пароли</b></summary>

В `/etc/naiveproxy/users.conf` с правами `600` (только root). Пароль не может содержать символ `:` — это требование формата файла.

</details>

---

## 📜 Changelog

<details>
<summary><b>v3.5.0</b> — Security Audit</summary>

- 🔒 `rm -rf` защита от пустой переменной `CONFIG_DIR`
- 🔒 `grep -vF` вместо `sed` для удаления пользователей (нет regex injection)
- 🔒 Безопасная замена пароля через `while+printf` (нет sed injection)
- 🔒 Валидация пароля — запрет символа `:`
- 🔒 `trap` cleanup временных файлов в self-update
- 🔒 `--data-urlencode` для Telegram (защита спецсимволов)
- 🔒 Watchdog FLAG перенесён в `/run` (нет race condition)
- 🐛 monitor.sh: проверка владельца конфига перед source

</details>

<details>
<summary><b>v3.4.0</b> — Camouflage Page</summary>

- ✨ Страница-камуфляж DevStack IT-блог (тёмная тема)
- ✨ Встроена в bash скрипт через heredoc
- 🆕 CLI команда `camouflage`
- 🆕 Меню пункт 15

</details>

<details>
<summary><b>v3.3.0</b> — Self-Update + Multi-Domain</summary>

- ✨ Self-update — обновление скрипта прямо из меню
- ✨ Фоновая проверка новых версий при запуске
- ✨ Управление несколькими доменами
- 🆕 CLI: `self-update`, `domains`, `version`

</details>

<details>
<summary><b>v3.2.0</b> — Certificate Monitor</summary>

- ✨ Проверка TLS сертификата — срок, цвет, алерт
- 🤖 Алерт в Telegram при сертификате < 7 дней
- 🆕 CLI команда `cert`

</details>

<details>
<summary><b>v3.1.0</b> — Bug Fixes</summary>

- 🐛 Фикс отката sshd_config (неверный путь бэкапа)
- 🐛 Фикс cron `update --auto` (несуществующий аргумент)
- 🐛 Фикс script_path при `bash <(curl)`
- 🔒 UFW: проверка активности перед правилами
- 🔒 SSH порт: проверка занятости через `ss`

</details>

<details>
<summary><b>v3.0.0</b> — System Hardening</summary>

- ✨ Обновление системы + unattended-upgrades
- ✨ SSH Hardening — ED25519, новый юзер, Fail2Ban
- 🆕 CLI: `ssh-hardening`, `sysupdate`

</details>

<details>
<summary><b>v2.x</b> — Core Features</summary>

- v2.1: Security audit — SHA256, валидация, source защита
- v2.0: Мультипользователь, Telegram-бот, Watchdog, Мониторинг

</details>

---

## 📄 Лицензия

MIT © [ivanstudiya-cpu](https://github.com/ivanstudiya-cpu)

---

<div align="center">

**Если скрипт помог — поставь ⭐ звезду**

[![GitHub stars](https://img.shields.io/github/stars/ivanstudiya-cpu/naiveproxy?style=for-the-badge&color=D4A017)](https://github.com/ivanstudiya-cpu/naiveproxy/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/ivanstudiya-cpu/naiveproxy?style=for-the-badge&color=58A6FF)](https://github.com/ivanstudiya-cpu/naiveproxy/network)

*NaiveProxy Manager · Caddy 2 · klzgrad/forwardproxy · Ubuntu*

</div>
