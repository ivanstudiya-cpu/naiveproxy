# 🛡️ NaiveProxy Manager

<div align="center">

![Bash](https://img.shields.io/badge/bash-5.0+-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Caddy](https://img.shields.io/badge/Caddy-2.x-00ADD8?style=for-the-badge&logo=caddy&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)

Bash-скрипт для быстрой установки и управления [NaiveProxy](https://github.com/klzgrad/naiveproxy) на Linux VPS.  
Стек: **Caddy 2** + **klzgrad/forwardproxy@naive**

[Установка](#-установка) • [Использование](#-использование) • [Клиентский конфиг](#-клиентский-конфиг) • [FAQ](#-faq)

</div>

---

## ✨ Возможности

- 🔧 **Полное меню управления** — установка, статус, смена пароля, обновление, удаление
- 🔍 **Проверка домена** — скрипт убедится, что DNS указывает на сервер до получения TLS
- 🔒 **probe_resistance** — сервер выглядит как обычный сайт для сканеров и цензоров
- 🌐 **HTTP/3 (QUIC)** — открывает 443/udp автоматически
- 🚀 **TCP BBR** — опциональное включение для ускорения
- 🛡️ **UFW** — автоматически открывает нужные порты
- 📦 **Автосборка Caddy** — xcaddy + forwardproxy собирается с нуля
- 💾 **Бэкап конфига** — перед каждым изменением
- 📋 **Клиентский конфиг** — URI, JSON для naive-client и sing-box

---

## 📋 Требования

| Параметр | Значение |
|----------|----------|
| ОС | Ubuntu 20.04 / 22.04 / 24.04 |
| Права | root |
| Домен | Указывает A-записью на IP сервера |
| Порты | 80, 443 (tcp + udp) |
| RAM | от 512 MB (сборка Go требует ~300 MB) |

---

## ⚡ Установка

```bash
wget -O naiveproxy.sh https://raw.githubusercontent.com/ivanstudiya-cpu/naiveproxy/main/naiveproxy.sh
chmod +x naiveproxy.sh
sudo bash naiveproxy.sh
```

Или одной командой:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ivanstudiya-cpu/naiveproxy/main/naiveproxy.sh)
```

---

## 🎮 Использование

### Интерактивное меню

```
sudo bash naiveproxy.sh
```

```
──────────────────────────────────────────
   NaiveProxy Manager
   Caddy + forwardproxy (klzgrad/naive)
──────────────────────────────────────────
   1) Установить NaiveProxy
   2) Статус
   3) Показать клиентский конфиг
   4) Сменить пароль
   5) Перезапустить Caddy
   6) Обновить Caddy
   7) Просмотр логов
   8) Удалить NaiveProxy
   0) Выход
──────────────────────────────────────────
```

### Аргументы командной строки

```bash
sudo bash naiveproxy.sh install   # Установить
sudo bash naiveproxy.sh status    # Статус
sudo bash naiveproxy.sh config    # Показать конфиг
sudo bash naiveproxy.sh restart   # Перезапустить
sudo bash naiveproxy.sh update    # Обновить Caddy
sudo bash naiveproxy.sh logs      # Логи
sudo bash naiveproxy.sh remove    # Удалить
```

---

## 📱 Клиентский конфиг

После установки скрипт выводит три формата:

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
| v2rayN | Windows | [GitHub](https://github.com/2dust/v2rayN) |
| naive | Linux CLI | [GitHub](https://github.com/klzgrad/naiveproxy/releases) |
| Hiddify | Android / Desktop | [GitHub](https://github.com/hiddify/hiddify-next) |

---

## 🔧 Как работает NaiveProxy

```
[Клиент] → [naive-client] → HTTPS/2 CONNECT → [Caddy + forwardproxy] → [Интернет]
              Chromium network stack         probe_resistance + TLS
```

NaiveProxy использует сетевой стек Chromium для маскировки трафика под обычный HTTPS браузера:
- **HTTP/2 CONNECT tunneling** — трафик выглядит как браузерный
- **TLS fingerprint** = Chrome — не детектируется по отпечатку
- **probe_resistance** — на probe-запросы отвечает как обычный сайт
- **Padding protocol** — противодействие анализу длины пакетов

---

## 📁 Файлы на сервере

```
/usr/local/bin/caddy          — бинарник Caddy
/etc/caddy/Caddyfile          — конфиг Caddy
/etc/naiveproxy/naive.conf    — параметры (домен, логин, пароль)
/etc/naiveproxy/backups/      — бэкапы Caddyfile
/var/www/html/index.html      — заглушка-сайт
/var/log/caddy/               — логи
/etc/systemd/system/caddy.service
```

---

## ❓ FAQ

**Сборка занимает слишком долго**  
Это нормально — xcaddy компилирует Go-код. На слабом VPS (1 vCPU) может занять до 10 минут.

**Caddy не запускается после установки**  
Проверь логи: `journalctl -u caddy -n 50`. Чаще всего проблема — домен не указывает на сервер или порт 80 занят.

**Можно ли использовать без домена?**  
Нет. NaiveProxy требует валидный TLS-сертификат, а Caddy получает его через Let's Encrypt по домену.

**Как проверить что всё работает?**  
```bash
curl -v --proxy "https://user:pass@your.domain.com:443" https://ifconfig.me
```

---

## 📄 Лицензия

MIT © [ivanstudiya-cpu](https://github.com/ivanstudiya-cpu)

---

<div align="center">
<sub>Если скрипт помог — ⭐ звезда приветствуется!</sub>
</div>
