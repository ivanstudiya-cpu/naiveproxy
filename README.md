# 🛡️ NaiveProxy Manager

<div align="center">

![Version](https://img.shields.io/badge/version-3.0.0-gold?style=for-the-badge)
![Bash](https://img.shields.io/badge/bash-5.0+-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Caddy](https://img.shields.io/badge/Caddy-2.x-00ADD8?style=for-the-badge&logo=caddy&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)

Bash-скрипт для установки и управления [NaiveProxy](https://github.com/klzgrad/naiveproxy) на Linux VPS.  
Стек: **Caddy 2** + **klzgrad/forwardproxy@naive**

[Установка](#-быстрая-установка) • [Возможности](#-возможности) • [SSH Hardening](#-ssh-hardening) • [Telegram](#-telegram-бот) • [FAQ](#-faq)

</div>

---

## ✨ Возможности

| Фича | Описание |
|------|----------|
| 🔄 Обновление системы | `apt upgrade` + автопатчи безопасности через `unattended-upgrades` |
| 🔒 SSH Hardening | Ключ ED25519, новый пользователь, смена порта, блокировка root |
| 🛡️ Fail2Ban | Автозащита от брутфорса: 3 попытки → бан на 24 часа |
| 🎛️ Меню управления | Установка, статус, обновление, удаление через интерактивное меню |
| 👥 Мультипользователь | Добавление/удаление пользователей без перезапуска |
| 🤖 Telegram-бот | Алерты при падении/подъёме + статистика по команде |
| 🔍 Проверка DNS | Скрипт убедится что домен указывает на сервер до получения TLS |
| 🕵️ probe_resistance | Сервер выглядит как обычный сайт для сканеров и цензоров |
| 👁️ Watchdog | Cron каждые 5 минут — автоперезапуск + алерт в Telegram |
| 🔄 Автообновление | Caddy обновляется автоматически каждое воскресенье в 3:00 |
| 📊 Мониторинг | Трафик, RAM, диск, uptime прямо в терминале или в Telegram |
| 🌐 HTTP/3 (QUIC) | Открывает 443/udp автоматически через UFW |
| 🚀 TCP BBR | Опциональное включение для ускорения |
| 💾 Бэкап конфига | Перед каждым изменением автоматически |
| 📋 Клиентский конфиг | URI, JSON для naive-client и sing-box |

---

## 📋 Требования

| Параметр | Значение |
|----------|----------|
| ОС | Ubuntu 20.04 / 22.04 / 24.04 |
| Права | root |
| Домен | A-запись → IP сервера |
| Порты | 80, 443 (tcp + udp) |
| RAM | от 512 MB |

---

## ⚡ Быстрая установка

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ivanstudiya-cpu/naiveproxy/main/naiveproxy.sh)
```

Или вручную:

```bash
wget -O naiveproxy.sh https://raw.githubusercontent.com/ivanstudiya-cpu/naiveproxy/main/naiveproxy.sh
chmod +x naiveproxy.sh
sudo bash naiveproxy.sh
```

---

## 🎮 Использование

### Интерактивное меню

```
sudo bash naiveproxy.sh
```

```
──────────────────────────────────────────
   NaiveProxy Manager v3.0.0
   Статус: ● работает  |  Домен: proxy.example.com
   Telegram: подключён  |  Юзеров: 3  |  SSH порт: 49217
──────────────────────────────────────────
   1)  Установить NaiveProxy
   2)  Статус
   3)  Клиентский конфиг
   4)  Управление пользователями
   5)  Мониторинг и статистика
   6)  Настройка Telegram
   7)  Перезапустить Caddy
   8)  Обновить Caddy
   9)  Логи
   10) Удалить NaiveProxy
   ──────────────────────────
   11) 🔒 SSH Hardening
   12) 🔄 Обновить систему
   0)  Выход
──────────────────────────────────────────
```

### Аргументы командной строки

```bash
sudo bash naiveproxy.sh install        # Установить (включает sysupdate + ssh-hardening)
sudo bash naiveproxy.sh sysupdate      # Обновить систему
sudo bash naiveproxy.sh ssh-hardening  # SSH Hardening
sudo bash naiveproxy.sh status         # Статус
sudo bash naiveproxy.sh config         # Показать конфиг
sudo bash naiveproxy.sh users          # Управление пользователями
sudo bash naiveproxy.sh monitor        # Мониторинг
sudo bash naiveproxy.sh restart        # Перезапустить
sudo bash naiveproxy.sh update         # Обновить Caddy
sudo bash naiveproxy.sh logs           # Логи
sudo bash naiveproxy.sh tg-stats       # Статистика в Telegram
sudo bash naiveproxy.sh remove         # Удалить
```

---

## 🔒 SSH Hardening

При первой установке (или через меню → 11) скрипт автоматически:

### 1. Создаёт нового sudo-пользователя
```
Имя нового пользователя: ivan
✓ Пользователь ivan создан с правами sudo
```

### 2. Генерирует ED25519 ключ
Если в `~/.ssh/authorized_keys` нет ключей — генерируется новая пара ED25519.  
Приватный ключ выводится прямо в терминал — **нужно скопировать и сохранить**.

```bash
# Сохрани ключ на своём компе:
# macOS/Linux:
echo "ВСТАВЬ_КЛЮЧ" > ~/.ssh/id_naiveproxy && chmod 600 ~/.ssh/id_naiveproxy

# Подключение после hardening:
ssh -i ~/.ssh/id_naiveproxy -p НОВЫЙ_ПОРТ ivan@YOUR_IP
```

### 3. Меняет SSH порт
Предлагает ввести вручную или сгенерировать случайный (49000–65000).

### 4. Применяет sshd_config
```
PermitRootLogin       no
PasswordAuthentication no
PubkeyAuthentication   yes
MaxAuthTries           3
LoginGraceTime         30
X11Forwarding          no
ClientAliveInterval    300
```

### 5. Настраивает UFW
- Открывает новый SSH порт
- Закрывает старый порт 22

### 6. Устанавливает Fail2Ban
```
maxretry = 3       # 3 неверных попытки
bantime  = 86400   # бан на 24 часа
findtime = 600     # в течение 10 минут
```

> ⚠️ **Важно:** перед тем как закрыть 22 порт, скрипт убеждается что новый порт открыт в UFW. Откат невозможен без доступа к консоли хостинга.

---

## 🔄 Обновление системы

При первой установке (или через меню → 12):

```bash
sudo bash naiveproxy.sh sysupdate
```

Выполняет:
- `apt update && apt upgrade -y` — полное обновление
- `apt autoremove && autoclean` — очистка
- Настройка `unattended-upgrades` — автопатчи безопасности ежедневно
- Проверка нужен ли `reboot` после обновления ядра

**Что обновляется автоматически:**
- ✅ Security-патчи Ubuntu (ежедневно)
- ✅ Caddy (каждое воскресенье в 3:00 через cron)
- ❌ Мажорные версии пакетов — только вручную (чтобы не сломать сервер)

---

## 🤖 Telegram-бот

### Настройка

1. Создай бота через [@BotFather](https://t.me/BotFather) → `/newbot`
2. Узнай chat_id через [@userinfobot](https://t.me/userinfobot)
3. Меню → **6) Настройка Telegram**

### Уведомления

| Событие | Сообщение |
|---------|-----------|
| Установка | ✅ NaiveProxy запущен |
| SSH Hardening | 🔒 Выполнен, новый порт |
| Обновление системы | 🔄 Обновлено |
| Падение сервиса | 🔴 Упал + попытка автоперезапуска |
| Обновление Caddy | 🔄 Старая → новая версия |
| Новый пользователь | 👤 Добавлен |
| Статистика | 📊 Полный отчёт |

---

## 📱 Клиентский конфиг

### URI
```
naive+https://user:password@your.domain.com:443
```

### JSON (naive-client)
```json
{
  "listen": "socks://127.0.0.1:1080",
  "proxy": "https://user:password@your.domain.com:443"
}
```

### JSON (sing-box)
```json
{
  "type": "http",
  "tag": "naiveproxy-out",
  "server": "your.domain.com",
  "server_port": 443,
  "username": "user",
  "password": "password",
  "tls": { "enabled": true, "server_name": "your.domain.com" }
}
```

### Клиенты

| Клиент | Платформа |
|--------|-----------|
| [NekoBox](https://github.com/MatsuriDayo/NekoBoxForAndroid) | Android |
| [sing-box](https://github.com/SagerNet/sing-box) | iOS / Android / Desktop |
| [Hiddify](https://github.com/hiddify/hiddify-next) | Android / Desktop |
| [v2rayN](https://github.com/2dust/v2rayN) | Windows |
| [naive](https://github.com/klzgrad/naiveproxy/releases) | Linux CLI |

---

## 📁 Файлы на сервере

```
/usr/local/bin/caddy                — бинарник Caddy
/etc/caddy/Caddyfile                — конфиг Caddy
/etc/naiveproxy/naive.conf          — параметры (домен, email, TG)
/etc/naiveproxy/users.conf          — список пользователей (chmod 600)
/etc/naiveproxy/backups/            — бэкапы Caddyfile
/etc/naiveproxy/monitor.sh          — watchdog
/etc/naiveproxy/.ssh_hardened       — маркер SSH hardening
/etc/naiveproxy/.sysupdate_done     — маркер обновления системы
/etc/fail2ban/jail.local            — конфиг Fail2Ban
/etc/apt/apt.conf.d/50unattended-upgrades
/var/www/html/index.html            — заглушка-сайт
/var/log/caddy/                     — логи
```

---

## 🔐 Безопасность (аудит v2.1 → v3.0)

| # | Защита |
|---|--------|
| 1 | `source config` — проверка владельца (root) и прав (600) перед загрузкой |
| 2 | Валидация домена по regex — запрет спецсимволов |
| 3 | Валидация логина пользователя — защита от sed-инъекции |
| 4 | SHA256-верификация бинарника Go после загрузки |
| 5 | Watchdog-флаг в `/run` вместо `/tmp` (защита от race condition) |
| 6 | `curl` к Telegram — `--max-time 10 --retry 2` |
| 7 | Три fallback для определения IP сервера |
| 8 | `set -euo pipefail` — скрипт падает при любой ошибке |
| 9 | ED25519 вместо RSA для SSH-ключей |
| 10 | Бэкап sshd_config перед изменениями |
| 11 | Проверка `sshd -t` перед перезапуском |
| 12 | UFW: новый SSH порт открывается ДО закрытия старого |

---

## ❓ FAQ

**Сборка Caddy занимает слишком долго**  
Нормально — xcaddy компилирует Go-код. На 1 vCPU до 10 минут.

**Заблокировал себя после SSH hardening**  
Зайди через консоль хостинга (VNC/KVM) и проверь: `ufw status`, `sshd -T | grep port`.

**Как проверить что NaiveProxy работает:**
```bash
curl -v --proxy "https://user:pass@your.domain.com:443" https://ifconfig.me
```

**Где хранятся пароли:**  
`/etc/naiveproxy/users.conf` — права 600, только root.

---

## 📄 Лицензия

MIT © [ivanstudiya-cpu](https://github.com/ivanstudiya-cpu)

---

<div align="center">
<sub>Если скрипт помог — ⭐ звезда приветствуется!</sub>
</div>
