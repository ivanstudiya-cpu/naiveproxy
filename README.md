# 🛡️ NaiveProxy Manager

<div align="center">

![Version](https://img.shields.io/badge/version-2.0.0-blue?style=for-the-badge)
![Bash](https://img.shields.io/badge/bash-5.0+-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Caddy](https://img.shields.io/badge/Caddy-2.x-00ADD8?style=for-the-badge&logo=caddy&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)

Bash-скрипт для установки и управления [NaiveProxy](https://github.com/klzgrad/naiveproxy) на Linux VPS.  
Стек: **Caddy 2** + **klzgrad/forwardproxy@naive**

[Установка](#-быстрая-установка) • [Возможности](#-возможности) • [Использование](#-использование) • [Telegram](#-telegram-бот) • [FAQ](#-faq)

</div>

---

## ✨ Возможности

| Фича | Описание |
|------|----------|
| 🎛️ Меню управления | Установка, статус, обновление, удаление через интерактивное меню |
| 👥 Мультипользователь | Добавление/удаление пользователей без перезапуска |
| 🤖 Telegram-бот | Алерты при падении/подъёме + статистика по команде |
| 🔍 Проверка DNS | Скрипт убедится, что домен указывает на сервер перед установкой |
| 🔒 probe_resistance | Сервер выглядит как обычный сайт для сканеров и цензоров |
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
| RAM | от 512 MB (сборка Go ~300 MB) |

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
   NaiveProxy Manager v2.0.0
   Статус: ● работает  |  Домен: proxy.example.com
   Telegram: подключён  |  Юзеров: 3
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
   0)  Выход
──────────────────────────────────────────
```

### Аргументы командной строки

```bash
sudo bash naiveproxy.sh install    # Установить
sudo bash naiveproxy.sh status     # Статус
sudo bash naiveproxy.sh config     # Показать конфиг
sudo bash naiveproxy.sh users      # Управление пользователями
sudo bash naiveproxy.sh monitor    # Мониторинг
sudo bash naiveproxy.sh restart    # Перезапустить
sudo bash naiveproxy.sh update     # Обновить Caddy
sudo bash naiveproxy.sh logs       # Логи
sudo bash naiveproxy.sh tg-stats   # Отправить статистику в Telegram
sudo bash naiveproxy.sh remove     # Удалить
```

---

## 👥 Мультипользователь

Меню → **4) Управление пользователями**:

- Просмотр всех пользователей с паролями
- Добавление нового пользователя (Caddy перезагружается без разрыва соединений)
- Удаление пользователя
- Смена пароля

При добавлении/удалении пользователя автоматически приходит уведомление в Telegram.

---

## 🤖 Telegram-бот

### Настройка

1. Создай бота через [@BotFather](https://t.me/BotFather) → `/newbot` → получи токен
2. Узнай свой chat_id через [@userinfobot](https://t.me/userinfobot)
3. Запусти скрипт → меню → **6) Настройка Telegram**

### Что присылает бот

| Событие | Уведомление |
|---------|-------------|
| Установка | ✅ NaiveProxy запущен |
| Падение | 🔴 Упал + попытка автоперезапуска |
| Перезапуск | ✅ Успешно перезапущен |
| Обновление Caddy | 🔄 Старая → новая версия |
| Новый пользователь | 👤 Добавлен логин |
| Удаление пользователя | 🗑 Удалён логин |
| Статистика по запросу | 📊 Полный отчёт |

### Пример статистики в Telegram

```
📊 Статистика NaiveProxy

🌐 Домен: proxy.example.com
📡 Статус: 🟢 Работает
🕐 Запущен: 2025-04-15 03:00
📦 Caddy: v2.8.4
👥 Пользователей: 3

📈 Трафик (с ребута):
⬇️ Входящий: 24.5G
⬆️ Исходящий: 8.2G

🖥 Сервер: vps-moscow
💾 RAM: 312M/1.0G
💿 Диск: 8.4G/25G (34%)
```

Вручную отправить статистику:

```bash
sudo bash naiveproxy.sh tg-stats
```

---

## 📊 Мониторинг

Меню → **5) Мониторинг и статистика** — показывает:

- Статус Caddy и время запуска
- Версию Caddy
- Количество пользователей
- Трафик входящий/исходящий (по сетевому интерфейсу)
- RAM, диск, uptime сервера
- Проверку доступности домена снаружи

### Watchdog (автоматический)

Каждые 5 минут cron проверяет статус Caddy. Если упал:
1. Шлёт алерт в Telegram
2. Пытается перезапустить
3. Сообщает результат

Каждое воскресенье в 3:00 — автообновление Caddy до последней версии.

---

## 📱 Клиентский конфиг

### URI (универсальный)
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

### JSON (sing-box outbound)
```json
{
  "type": "http",
  "tag": "naiveproxy-out",
  "server": "your.domain.com",
  "server_port": 443,
  "username": "user",
  "password": "password",
  "tls": {
    "enabled": true,
    "server_name": "your.domain.com"
  }
}
```

### Поддерживаемые клиенты

| Клиент | Платформа | Ссылка |
|--------|-----------|--------|
| NekoBox | Android | [GitHub](https://github.com/MatsuriDayo/NekoBoxForAndroid) |
| sing-box | iOS / Android / Desktop | [GitHub](https://github.com/SagerNet/sing-box) |
| Hiddify | Android / Desktop | [GitHub](https://github.com/hiddify/hiddify-next) |
| v2rayN | Windows | [GitHub](https://github.com/2dust/v2rayN) |
| naive | Linux CLI | [Releases](https://github.com/klzgrad/naiveproxy/releases) |

---

## 🔧 Как работает NaiveProxy

```
[Клиент]        [Cenzor]        [Сервер]           [Internet]
   │                │                │                   │
   ├── naive ──────►│── HTTPS/2 ────►│── Caddy ─────────►│
   │   Chromium     │   выглядит     │   forwardproxy     │
   │   network      │   как Chrome   │   probe_resistance │
   │   stack        │                │                    │
```

- **HTTP/2 CONNECT tunneling** — трафик неотличим от браузерного
- **TLS fingerprint = Chrome** — не детектируется по отпечатку
- **probe_resistance** — на probe-запросы отвечает как обычный сайт
- **Padding protocol** — противодействие анализу длины пакетов

---

## 📁 Файлы на сервере

```
/usr/local/bin/caddy              — бинарник Caddy
/etc/caddy/Caddyfile              — конфиг Caddy
/etc/naiveproxy/naive.conf        — параметры (домен, email, TG)
/etc/naiveproxy/users.conf        — список пользователей
/etc/naiveproxy/backups/          — бэкапы Caddyfile
/etc/naiveproxy/monitor.sh        — watchdog скрипт
/var/www/html/index.html          — заглушка-сайт
/var/log/caddy/                   — логи
/etc/systemd/system/caddy.service — systemd unit
```

---

## ❓ FAQ

**Сборка занимает слишком долго**  
Нормально — xcaddy компилирует Go-код. На 1 vCPU до 10 минут.

**Caddy не запускается**  
Смотри лог: `journalctl -u caddy -n 50`. Чаще всего — домен не указывает на сервер или занят порт 80.

**Как проверить что всё работает?**
```bash
curl -v --proxy "https://user:pass@your.domain.com:443" https://ifconfig.me
```

**Можно ли без домена?**  
Нет. Нужен валидный TLS от Let's Encrypt.

**Где хранятся пароли?**  
В `/etc/naiveproxy/users.conf` с правами 600 (только root).

---

## 📄 Лицензия

MIT © [ivanstudiya-cpu](https://github.com/ivanstudiya-cpu)

---

<div align="center">
<sub>Если скрипт помог — ⭐ звезда приветствуется!</sub>
</div>
