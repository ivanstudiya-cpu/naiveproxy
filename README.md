<div align="center">

# 🛡️ NaiveProxy Manager

**Полноценный менеджер приватного прокси-сервера на базе Caddy 2 + NaiveProxy**  
Установка, безопасность, мониторинг и управление — всё в одном bash-скрипте

---

[![Version](https://img.shields.io/badge/version-3.3.0-D4A017?style=for-the-badge&logo=github)](https://github.com/ivanstudiya-cpu/naiveproxy/releases)
[![Bash](https://img.shields.io/badge/bash-5.0+-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Caddy](https://img.shields.io/badge/Caddy-2.x-00ADD8?style=for-the-badge&logo=caddy&logoColor=white)](https://caddyserver.com)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-brightgreen?style=for-the-badge)](https://www.shellcheck.net)
[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](LICENSE)

---

[**Быстрый старт**](#-быстрый-старт) • [**Возможности**](#-возможности) • [**SSH Hardening**](#-ssh-hardening) • [**Telegram**](#-telegram-бот) • [**Клиенты**](#-клиентские-приложения) • [**FAQ**](#-faq)

</div>

---

## 🤔 Что это и зачем

**NaiveProxy** — прокси-протокол который маскирует трафик под обычный браузер Chrome. Цензоры и DPI-системы видят легитимный HTTPS/2 и пропускают.

**NaiveProxy Manager** — bash-скрипт который превращает голый VPS в полноценный приватный прокси-сервер за 10 минут. Без Docker, без панелей управления, без лишних зависимостей.

```
Твой телефон/ноутбук  ──►  [Цензор/DPI]  ──►  Твой VPS  ──►  Интернет
        │                        │                  │
   naive-client             Видит Chrome       Caddy + NaiveProxy
   Chromium network         HTTPS/2 трафик     forwardproxy
   stack                    Пропускает ✓       probe_resistance
```

---

## ✨ Возможности

<table>
<tr>
<td width="50%">

### 🔐 Безопасность сервера
- **SSH Hardening** — ED25519 ключ, смена порта, блокировка root
- **Fail2Ban** — 3 попытки → бан на 24 часа
- **UFW** — только нужные порты, остальное закрыто
- **Автообновления** — security-патчи ежедневно
- **probe_resistance** — сервер выглядит как обычный сайт

</td>
<td width="50%">

### 📡 Управление прокси
- **Мультипользователь** — добавление/удаление без рестарта
- **Автоматический TLS** — Let's Encrypt через Caddy
- **Проверка сертификата** — срок, дней до истечения, алерт
- **HTTP/3 (QUIC)** — автоматически на 443/udp
- **TCP BBR** — опциональное ускорение

</td>
</tr>
<tr>
<td width="50%">

### 🤖 Мониторинг
- **Telegram-бот** — алерты о падении, подъёме, обновлениях
- **Watchdog** — cron каждые 5 минут, автоперезапуск
- **Статистика** — трафик, RAM, диск, uptime в реальном времени
- **Проверка домена** — доступность снаружи + HTTP-код
- **Автообновление Caddy** — каждое воскресенье в 3:00

</td>
<td width="50%">

### 🛡️ Надёжность кода
- `set -euo pipefail` — падает при любой ошибке
- **SHA256-верификация** бинарника Go после загрузки
- **Валидация всех входных данных** — домен, логин, порт
- **Бэкап конфига** перед каждым изменением
- **ShellCheck passing** — нет предупреждений

</td>
</tr>
</table>

---

## 📋 Требования

| Параметр | Требование |
|----------|-----------|
| ОС | Ubuntu 20.04 / 22.04 / 24.04 |
| Права | root |
| Домен | A-запись → IP сервера |
| Порты | 80/tcp, 443/tcp, 443/udp |
| RAM | от 512 MB (сборка Go ~300 MB) |
| Место | от 1 GB |

---

## ⚡ Быстрый старт

### Одна команда:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ivanstudiya-cpu/naiveproxy/main/naiveproxy.sh)
```

### Или скачать и запустить:

```bash
wget -O naiveproxy.sh https://raw.githubusercontent.com/ivanstudiya-cpu/naiveproxy/main/naiveproxy.sh
chmod +x naiveproxy.sh
sudo bash naiveproxy.sh
```

> ⚠️ При первом запуске скрипт последовательно предложит: обновить систему → настроить SSH → установить NaiveProxy. Каждый шаг можно пропустить.

### Что происходит при установке:

```
[1/5] 🔄 Обновление системы
      apt upgrade + настройка unattended-upgrades

[2/5] 🔒 SSH Hardening
      Новый пользователь + ED25519 ключ + смена порта + Fail2Ban

[3/5] 📦 Сборка Caddy
      xcaddy + klzgrad/forwardproxy@naive (3-10 минут)

[4/5] ⚙️  Настройка
      Caddyfile + systemd + UFW + BBR + Telegram (опц.)

[5/5] ✅ Готово
      Выводит URI и JSON конфиги для всех клиентов
```

---

## 🎮 Интерфейс

```
──────────────────────────────────────────
   NaiveProxy Manager v3.3.0
   Статус: ● работает  |  Домен: proxy.example.com
   Telegram: подключён  |  Юзеров: 3  |  SSH порт: 52847
──────────────────────────────────────────
   1)  Установить NaiveProxy
   2)  Статус
   3)  Клиентский конфиг
   4)  Управление пользователями
   5)  🌐 Управление доменами
   6)  Мониторинг и статистика
   7)  Настройка Telegram
   7)  Перезапустить Caddy
   8)  Обновить Caddy
   9)  Логи
   10) Логи
   11) Удалить NaiveProxy
   ──────────────────────────
   12) 🔒 SSH Hardening
   13) 🔄 Обновить систему
   14) ⬆️  Обновить скрипт
   0)  Выход
──────────────────────────────────────────
```

### CLI без меню:

```bash
sudo bash naiveproxy.sh install        # Полная установка
sudo bash naiveproxy.sh status         # Статус + сертификат
sudo bash naiveproxy.sh cert           # Только сертификат
sudo bash naiveproxy.sh config         # Клиентский конфиг
sudo bash naiveproxy.sh users          # Управление пользователями
sudo bash naiveproxy.sh monitor        # Мониторинг + статистика
sudo bash naiveproxy.sh restart        # Перезапустить Caddy
sudo bash naiveproxy.sh update         # Обновить Caddy
sudo bash naiveproxy.sh logs           # Логи в реальном времени
sudo bash naiveproxy.sh tg-stats       # Статистика в Telegram
sudo bash naiveproxy.sh ssh-hardening  # SSH Hardening
sudo bash naiveproxy.sh sysupdate      # Обновление системы
sudo bash naiveproxy.sh remove         # Удалить всё
sudo bash naiveproxy.sh domains        # Управление доменами
sudo bash naiveproxy.sh self-update    # Обновить скрипт
sudo bash naiveproxy.sh version        # Показать версию
```

---


---

## 🌐 Несколько доменов

```bash
sudo bash naiveproxy.sh domains
```

```
  1) Список доменов
  2) Добавить домен     ← проверяет DNS, получает TLS, перезагружает Caddy
  3) Удалить домен
```

Caddy автоматически получает сертификат для каждого нового домена. Все пользователи работают на всех доменах — полезно для резервирования или разных регионов.

---

## ⬆️ Автообновление скрипта

При запуске меню скрипт **тихо в фоне** проверяет наличие новой версии на GitHub и показывает подсказку:

```
  ⬆  Доступно обновление скрипта: v3.3.0 → v3.4.0
     Меню → 14) Обновить скрипт
```

Обновить вручную:
```bash
sudo bash naiveproxy.sh self-update
```

Что происходит при обновлении:
1. Проверяет версию через GitHub API
2. Скачивает новый скрипт
3. Проверяет синтаксис (`bash -n`) — не установит сломанную версию
4. Делает бэкап текущей версии (`naiveproxy.sh.v3.3.0.bak`)
5. Устанавливает новую версию и перезапускается

## 🔒 SSH Hardening

Запускается автоматически при первой установке или вручную через меню → **11**.

### Что делает пошагово:

**Шаг 1 — Новый sudo-пользователь**
```
Имя нового пользователя: ivan
✓ Пользователь ivan создан с правами sudo
✓ Сгенерирован пароль: Xk9mP2qR7nL4vT8w  ← СОХРАНИ!
```

**Шаг 2 — ED25519 ключ**

Если в `authorized_keys` нет ключей — генерируется новая пара ED25519.
Приватный ключ выводится в терминал — нужно скопировать и сохранить.

```bash
# Сохрани на своём компе:
echo "ВСТАВЬ_КЛЮЧ" > ~/.ssh/id_naiveproxy && chmod 600 ~/.ssh/id_naiveproxy

# Подключение после hardening:
ssh -i ~/.ssh/id_naiveproxy -p НОВЫЙ_ПОРТ ivan@YOUR_IP
```

**Шаг 3 — Смена SSH порта**

```
1) Ввести вручную
2) Случайный (49000-65000)  ← рекомендуется
0) Оставить 22
```

Случайный порт проверяется через `ss -tlnp` — не назначается занятый.

**Шаг 4 — sshd_config**

```ini
PermitRootLogin        no
PasswordAuthentication no
PubkeyAuthentication   yes
MaxAuthTries           3
LoginGraceTime         30
X11Forwarding          no
PermitEmptyPasswords   no
ClientAliveInterval    300
```

**Шаг 5 — UFW + Fail2Ban**
```
✓ Новый SSH порт открыт в UFW
✓ Старый порт 22 закрыт в UFW
✓ Fail2Ban: 3 попытки → бан 24 часа
```

> ⚠️ Новый порт открывается в UFW **до** закрытия старого. При ошибке в конфиге — откат по сохранённому бэкапу.

---

## 🤖 Telegram-бот

### Настройка (2 минуты):

1. Создай бота: [@BotFather](https://t.me/BotFather) → `/newbot`
2. Узнай chat_id: [@userinfobot](https://t.me/userinfobot)
3. Меню → **6) Настройка Telegram**

### Что приходит в Telegram:

| Событие | Сообщение |
|---------|-----------|
| Установка завершена | ✅ NaiveProxy запущен |
| Caddy упал | 🔴 Упал → пытаюсь перезапустить |
| Перезапуск успешен | ✅ Перезапущен |
| Перезапуск не помог | ❌ Нужно вмешательство |
| Caddy обновлён | 🔄 Версия X → Y |
| SSH Hardening | 🔒 Выполнен, новый порт |
| Обновление системы | 🔄 Система обновлена |
| Новый пользователь | 👤 Добавлен логин |
| Удалён пользователь | 🗑 Удалён логин |
| Сертификат < 7 дней | ⚠️ Скоро истекает! |
| Статистика по запросу | 📊 Полный отчёт |

### Пример статистики в Telegram:

```
📊 Статистика NaiveProxy

🌐 Домен: proxy.example.com
📡 Статус: 🟢 Работает
🕐 Запущен: 2026-04-01 03:00
📦 Caddy: v2.9.1
👥 Пользователей: 3

📈 Трафик (с ребута):
⬇️ Входящий:  38.4G
⬆️ Исходящий: 12.1G

🖥 Сервер: vps-01
💾 RAM: 412M/1.0G
💿 Диск: 9.2G/25G (37%)

🔐 Сертификат:
📅 Истекает: Jul 22 2026 GMT
⏳ Осталось: 90 дней
```

---

## 🔐 Сертификат TLS

Caddy получает и обновляет сертификат **автоматически** через Let's Encrypt.
Тебе ничего делать не нужно — Caddy обновит за 30 дней до истечения.

Скрипт добавляет мониторинг статуса:

```
  TLS Сертификат:
  Домен:     proxy.example.com
  Истекает:  Jul 22 01:28:35 2026 GMT
  Осталось:  90 дней                    ← 🟢 зелёный
  Выдан:     Let's Encrypt
```

| Дней осталось | Индикация | Действие |
|--------------|-----------|----------|
| > 30 | 🟢 Зелёный | Всё хорошо |
| 7–30 | 🟡 Жёлтый | Предупреждение |
| < 7 | 🔴 Красный | Алерт в Telegram |

```bash
# Проверить вручную:
sudo bash naiveproxy.sh cert
```

---

## 👥 Мультипользователь

```bash
sudo bash naiveproxy.sh users
```

```
  1) Список пользователей
  2) Добавить пользователя     ← caddy reload, сессии не прерываются
  3) Удалить пользователя
  4) Сменить пароль
```

Каждый пользователь — отдельный URI:
```
naive+https://alice:pass1@proxy.example.com:443
naive+https://bob:pass2@proxy.example.com:443
```

---

## 📱 Клиентские приложения

### URI (вставляется в любой клиент)
```
naive+https://USERNAME:PASSWORD@YOUR_DOMAIN:443
```

### JSON для naive-client
```json
{
  "listen": "socks://127.0.0.1:1080",
  "proxy": "https://USERNAME:PASSWORD@YOUR_DOMAIN:443"
}
```

### JSON для sing-box
```json
{
  "type": "http",
  "tag": "naiveproxy-out",
  "server": "YOUR_DOMAIN",
  "server_port": 443,
  "username": "USERNAME",
  "password": "PASSWORD",
  "tls": {
    "enabled": true,
    "server_name": "YOUR_DOMAIN"
  }
}
```

### Рекомендуемые клиенты

| Клиент | Платформа | Ссылка |
|--------|-----------|--------|
| NekoBox | Android | [GitHub](https://github.com/MatsuriDayo/NekoBoxForAndroid/releases) |
| Hiddify | Android / iOS / Windows / macOS | [GitHub](https://github.com/hiddify/hiddify-next/releases) |
| sing-box | Все платформы | [GitHub](https://github.com/SagerNet/sing-box) |
| v2rayN | Windows | [GitHub](https://github.com/2dust/v2rayN/releases) |
| naive | Linux CLI | [GitHub](https://github.com/klzgrad/naiveproxy/releases) |

> ⚠️ v2rayNG **не поддерживает** NaiveProxy. Используй NekoBox или Hiddify.

### Проверить без клиента:
```bash
curl -v --proxy "https://USERNAME:PASSWORD@YOUR_DOMAIN:443" https://ifconfig.me
```

---

## 🔄 Автообновление системы

```bash
sudo bash naiveproxy.sh sysupdate
```

| Компонент | Периодичность | Способ |
|-----------|--------------|--------|
| Security-патчи Ubuntu | Ежедневно | unattended-upgrades |
| Caddy + forwardproxy | Воскресенье 3:00 | cron |
| Мажорные пакеты | Вручную | `sysupdate` |

---

## 📁 Файлы на сервере

```
/usr/local/bin/caddy
/etc/caddy/Caddyfile                      (chmod 600)
/etc/naiveproxy/
├── naive.conf                            (chmod 600) — домен, TG токен
├── users.conf                            (chmod 600) — логины:пароли
├── monitor.sh                            — watchdog
├── .ssh_hardened                         — маркер SSH hardening
├── .sysupdate_done                       — маркер обновления
└── backups/Caddyfile.YYYYMMDD_HHMMSS    — бэкапы
/etc/fail2ban/jail.local
/var/www/html/index.html                  — заглушка-сайт
/var/log/caddy/access.log
/var/log/caddy/naive.log
/etc/systemd/system/caddy.service
```

---

## 🔐 Модель безопасности

```
Сервер закрыт снаружи:
  ✓ UFW: только 80, 443/tcp, 443/udp + SSH порт
  ✓ SSH: только ключ, root запрещён, нестандартный порт
  ✓ Fail2Ban: автобан брутфорса

Прокси скрыт от сканеров:
  ✓ probe_resistance: выглядит как обычный сайт
  ✓ TLS fingerprint = Chrome (Chromium network stack)
  ✓ HTTP/2 CONNECT: неотличимо от браузерного трафика

Код безопасен:
  ✓ SHA256 верификация Go бинарника
  ✓ Валидация домена, логинов, портов
  ✓ Защита от sed-инъекций в именах пользователей
  ✓ source конфига только если владелец root и права 600
  ✓ Watchdog-флаг в /run (не /tmp)
  ✓ ShellCheck passing
```

---

## ❓ FAQ

<details>
<summary><b>Сборка Caddy занимает очень долго</b></summary>

Нормально — xcaddy компилирует Go-код с нуля. На VPS с 1 vCPU занимает 5-10 минут. Не прерывай.

</details>

<details>
<summary><b>Заблокировал себя после SSH hardening</b></summary>

Зайди через консоль хостинга (VNC/KVM) и выполни:
```bash
ufw allow 22/tcp
systemctl restart sshd
```

</details>

<details>
<summary><b>Caddy не получает сертификат</b></summary>

```bash
dig +short YOUR_DOMAIN          # домен должен указывать на этот IP
ss -tlnp | grep :80             # порт 80 должен быть свободен
journalctl -u caddy -n 50 | grep -i "error\|acme"
```

</details>

<details>
<summary><b>v2rayNG не работает</b></summary>

v2rayNG не поддерживает NaiveProxy. Используй NekoBox (Android) или Hiddify (все платформы).

</details>

<details>
<summary><b>Как добавить пользователя без разрыва сессий</b></summary>

```bash
sudo bash naiveproxy.sh users  # → 2) Добавить
```

Используется `caddy reload` — активные соединения не прерываются.

</details>

---

## 📊 Сравнение с аналогами

| Функция | NaiveProxy Manager | x-ui / 3x-ui | Marzban |
|---------|:-----------------:|:------------:|:-------:|
| Без Docker | ✅ | ❌ | ❌ |
| SSH Hardening | ✅ | ❌ | ❌ |
| Обновление системы | ✅ | ❌ | ❌ |
| Проверка сертификата | ✅ | ❌ | ❌ |
| Watchdog + автоперезапуск | ✅ | ❌ | ❌ |
| SHA256 верификация | ✅ | ❌ | ❌ |
| probe_resistance | ✅ | ❌ | ❌ |
| Telegram алерты | ✅ | ✅ | ✅ |
| ShellCheck passing | ✅ | — | — |

---

## 📜 Changelog

### v3.3.0
- ✨ Self-update — обновление скрипта прямо из меню
- ✨ Фоновая проверка новых версий при запуске
- ✨ Управление несколькими доменами (multi-domain Caddyfile)
- 🆕 CLI команды: `self-update`, `domains`, `version`

### v3.2.0
- ✨ Проверка TLS сертификата — срок, дней до истечения, цвет
- 🤖 Алерт в Telegram при сертификате < 7 дней
- 📊 Инфо о сертификате в tg-stats
- 🆕 CLI команда `cert`

### v3.1.0
- 🐛 Фикс отката sshd_config (неверный бэкап)
- 🐛 Фикс cron `update --auto`
- 🐛 Фикс script_path при `bash <(curl)`
- 🔒 UFW: проверка активности перед правилами
- 🔒 Случайный SSH порт: проверка занятости
- 🔒 `chpasswd`: echo → printf

### v3.0.0
- ✨ Обновление системы + unattended-upgrades
- ✨ SSH Hardening — ED25519, новый юзер, Fail2Ban
- 🆕 CLI: `ssh-hardening`, `sysupdate`

### v2.1.0
- 🔒 SHA256 верификация Go, валидация ввода
- 🐛 Watchdog флаг в /run вместо /tmp

### v2.0.0
- ✨ Мультипользователь, Telegram-бот, Watchdog, Мониторинг

---

## 📄 Лицензия

MIT © [ivanstudiya-cpu](https://github.com/ivanstudiya-cpu)

---

<div align="center">

**Если скрипт помог — поставь ⭐ звезду, это мотивирует развивать проект**

[![GitHub stars](https://img.shields.io/github/stars/ivanstudiya-cpu/naiveproxy?style=social)](https://github.com/ivanstudiya-cpu/naiveproxy/stargazers)

</div>
