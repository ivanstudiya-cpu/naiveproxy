#!/bin/bash
# ============================================================
#   NaiveProxy Manager v2.1.0 — by ivanstudiya-cpu
#   Стек: Caddy 2 + klzgrad/forwardproxy@naive
#   ОС: Ubuntu 20.04 / 22.04 / 24.04
#   GitHub: https://github.com/ivanstudiya-cpu/naiveproxy
# ============================================================

set -euo pipefail

VERSION="2.1.0"

# ─── Цвета ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}[✓]${RESET} $*"; }
err()  { echo -e "${RED}[✗]${RESET} $*"; }
info() { echo -e "${CYAN}[i]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }
hr()   { echo -e "${CYAN}──────────────────────────────────────────${RESET}"; }

# ─── Пути ────────────────────────────────────────────────────
CADDY_BIN="/usr/local/bin/caddy"
CADDY_SERVICE="/etc/systemd/system/caddy.service"
CADDYFILE="/etc/caddy/Caddyfile"
CADDY_DIR="/etc/caddy"
WEBROOT="/var/www/html"
CONFIG_FILE="/etc/naiveproxy/naive.conf"
CONFIG_DIR="/etc/naiveproxy"
USERS_FILE="/etc/naiveproxy/users.conf"
LOG_DIR="/var/log/caddy"
BACKUP_DIR="/etc/naiveproxy/backups"
MONITOR_SCRIPT="/etc/naiveproxy/monitor.sh"

# ─── Проверки ────────────────────────────────────────────────
check_root() {
    if [[ $EUID -ne 0 ]]; then
        err "Запускай от root: sudo bash $0"
        exit 1
    fi
}

check_os() {
    if ! grep -qiE "ubuntu|debian" /etc/os-release 2>/dev/null; then
        warn "Скрипт тестировался на Ubuntu/Debian. Продолжаем на свой страх и риск."
    fi
}

check_installed() {
    [[ -f "$CADDY_BIN" && -f "$CADDYFILE" ]]
}

# ─── Конфиг ──────────────────────────────────────────────────
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # Безопасность: проверяем владельца и права перед source
        local owner perms
        owner=$(stat -c '%U' "$CONFIG_FILE" 2>/dev/null || echo "unknown")
        perms=$(stat -c '%a' "$CONFIG_FILE" 2>/dev/null || echo "000")
        if [[ "$owner" != "root" ]]; then
            err "БЕЗОПАСНОСТЬ: $CONFIG_FILE принадлежит '$owner', ожидается root. Прерываю."
            exit 1
        fi
        [[ "$perms" != "600" ]] && chmod 600 "$CONFIG_FILE"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    fi
}

save_config() {
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" <<EOF
DOMAIN="${DOMAIN:-}"
EMAIL="${EMAIL:-}"
TG_TOKEN="${TG_TOKEN:-}"
TG_CHAT_ID="${TG_CHAT_ID:-}"
INSTALLED_AT="$(date '+%Y-%m-%d %H:%M:%S')"
EOF
    chmod 600 "$CONFIG_FILE"
}

# ─── Пользователи ────────────────────────────────────────────
load_users() {
    if [[ ! -f "$USERS_FILE" ]]; then
        mkdir -p "$CONFIG_DIR"
        echo "" > "$USERS_FILE"
        chmod 600 "$USERS_FILE"
    fi
}

get_users() {
    grep -v '^#\|^[[:space:]]*$' "$USERS_FILE" 2>/dev/null || true
}

# ─── Telegram ────────────────────────────────────────────────
tg_send() {
    local message="$1"
    [[ -z "${TG_TOKEN:-}" || -z "${TG_CHAT_ID:-}" ]] && return 0
    curl -s --max-time 10 --retry 2 --retry-delay 3 \
        -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d chat_id="${TG_CHAT_ID}" \
        -d parse_mode="HTML" \
        -d text="${message}" \
        >/dev/null 2>&1 || true
}

tg_alert_up() {
    tg_send "✅ <b>NaiveProxy запущен</b>
🌐 Домен: <code>${DOMAIN:-unknown}</code>
🕐 $(date '+%Y-%m-%d %H:%M:%S')
📡 Сервер: $(hostname)"
}

tg_alert_down() {
    tg_send "🔴 <b>NaiveProxy упал!</b>
🌐 Домен: <code>${DOMAIN:-unknown}</code>
🕐 $(date '+%Y-%m-%d %H:%M:%S')
📡 Сервер: $(hostname)
⚠️ Требуется вмешательство!"
}

tg_alert_updated() {
    local old_ver="$1" new_ver="$2"
    tg_send "🔄 <b>Caddy обновлён</b>
📦 Было: <code>${old_ver}</code>
📦 Стало: <code>${new_ver}</code>
🕐 $(date '+%Y-%m-%d %H:%M:%S')"
}

tg_send_stats() {
    if ! check_installed; then
        tg_send "❌ NaiveProxy не установлен"
        return
    fi

    local status="🔴 Остановлен"
    systemctl is-active --quiet caddy 2>/dev/null && status="🟢 Работает"

    local uptime_str
    uptime_str=$(systemctl show caddy --property=ActiveEnterTimestamp 2>/dev/null \
        | cut -d= -f2 | xargs -I{} date -d "{}" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "н/д")

    local caddy_ver
    caddy_ver=$("$CADDY_BIN" version 2>/dev/null | head -1 | awk '{print $1}' || echo "н/д")

    local iface rx tx
    iface=$(ip route | awk '/default/{print $5}' | head -1)
    rx=$(cat /sys/class/net/"$iface"/statistics/rx_bytes 2>/dev/null || echo 0)
    tx=$(cat /sys/class/net/"$iface"/statistics/tx_bytes 2>/dev/null || echo 0)
    rx=$(numfmt --to=iec "$rx" 2>/dev/null || echo "н/д")
    tx=$(numfmt --to=iec "$tx" 2>/dev/null || echo "н/д")

    local users_count
    users_count=$(get_users | wc -l)

    tg_send "📊 <b>Статистика NaiveProxy</b>

🌐 Домен: <code>${DOMAIN:-н/д}</code>
📡 Статус: ${status}
🕐 Запущен: ${uptime_str}
📦 Caddy: <code>${caddy_ver}</code>
👥 Пользователей: ${users_count}

📈 <b>Трафик (с ребута):</b>
⬇️ Входящий: <code>${rx}</code>
⬆️ Исходящий: <code>${tx}</code>

🖥 Сервер: <code>$(hostname)</code>
💾 RAM: $(free -h | awk '/Mem:/{print $3"/"$2}')
💿 Диск: $(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')"
}

# ─── Настройка Telegram ───────────────────────────────────────
setup_telegram() {
    hr
    echo -e "${BOLD}  Настройка Telegram-бота${RESET}"
    hr
    echo
    info "Нужен токен бота и твой chat_id."
    info "Создать бота: @BotFather → /newbot"
    info "Узнать chat_id: напиши боту @userinfobot"
    echo

    echo -ne "${CYAN}Bot Token (Enter чтобы пропустить): ${RESET}"
    read -r input_token
    [[ -z "$input_token" ]] && { warn "Telegram пропущен"; return; }

    echo -ne "${CYAN}Chat ID: ${RESET}"
    read -r input_chat_id
    [[ -z "$input_chat_id" ]] && { warn "Telegram пропущен"; return; }

    info "Проверяю токен..."
    local response
    response=$(curl -s "https://api.telegram.org/bot${input_token}/getMe" 2>/dev/null || echo "{}")
    if echo "$response" | grep -q '"ok":true'; then
        local bot_name
        bot_name=$(echo "$response" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
        ok "Бот найден: @${bot_name}"
    else
        err "Токен неверный или бот недоступен"
        return
    fi

    TG_TOKEN="$input_token"
    TG_CHAT_ID="$input_chat_id"
    save_config

    tg_send "🤖 <b>NaiveProxy Manager подключён!</b>
✅ Telegram-уведомления настроены
📡 Сервер: <code>$(hostname)</code>
🕐 $(date '+%Y-%m-%d %H:%M:%S')

<b>Доступные команды в скрипте:</b>
• статус — bash naiveproxy.sh tg-stats
• мониторинг — каждые 5 минут автоматически"
    ok "Тестовое сообщение отправлено"
}

# ─── Watchdog (cron) ─────────────────────────────────────────
install_monitor() {
    cat > "$MONITOR_SCRIPT" <<'MONITOR'
#!/bin/bash
CONFIG_FILE="/etc/naiveproxy/naive.conf"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

tg_send() {
    local msg="$1"
    [[ -z "${TG_TOKEN:-}" || -z "${TG_CHAT_ID:-}" ]] && return
    curl -s --max-time 10 --retry 2 \
        -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d chat_id="${TG_CHAT_ID}" \
        -d parse_mode="HTML" \
        -d text="${msg}" >/dev/null 2>&1 || true
}

FLAG="/run/naiveproxy_was_down"

if ! systemctl is-active --quiet caddy 2>/dev/null; then
    if [[ ! -f "$FLAG" ]]; then
        touch "$FLAG"
        tg_send "🔴 <b>NaiveProxy упал!</b>
🌐 Домен: <code>${DOMAIN:-unknown}</code>
🕐 $(date '+%Y-%m-%d %H:%M:%S')
🔄 Пытаюсь перезапустить..."
        systemctl restart caddy 2>/dev/null || true
        sleep 5
        if systemctl is-active --quiet caddy; then
            tg_send "✅ <b>Перезапущен успешно</b>
🕐 $(date '+%Y-%m-%d %H:%M:%S')"
            rm -f "$FLAG"
        else
            tg_send "❌ <b>Перезапуск не помог!</b> Нужно ручное вмешательство."
        fi
    fi
else
    rm -f "$FLAG"
fi
MONITOR

    chmod +x "$MONITOR_SCRIPT"

    local script_path
    script_path=$(realpath "$0" 2>/dev/null || echo "/usr/local/bin/naiveproxy.sh")

    # Очищаем старые naive-cron записи, добавляем новые
    ( crontab -l 2>/dev/null | grep -v "naiveproxy\|monitor\.sh" || true
      echo "*/5 * * * * /bin/bash $MONITOR_SCRIPT"
      echo "0 3 * * 0 /bin/bash ${script_path} update --auto >> ${LOG_DIR}/autoupdate.log 2>&1"
    ) | crontab -

    ok "Watchdog: каждые 5 минут"
    ok "Автообновление Caddy: воскресенье 3:00"
}

# ─── Проверка домена ─────────────────────────────────────────
check_domain() {
    local domain="$1"
    info "Проверяю DNS для $domain..."

    local server_ip domain_ip
    server_ip=$(curl -s4 --max-time 5 https://ifconfig.me 2>/dev/null         || curl -s4 --max-time 5 https://api.ipify.org 2>/dev/null         || curl -s4 --max-time 5 https://checkip.amazonaws.com 2>/dev/null         || echo "")
    domain_ip=$(getent hosts "$domain" 2>/dev/null | awk '{print $1}' | head -1 || echo "")

    if [[ -z "$domain_ip" ]]; then
        err "Домен $domain не резолвится. Проверь DNS."
        exit 1
    fi

    if [[ "$server_ip" != "$domain_ip" ]]; then
        warn "IP сервера: $server_ip  |  IP домена: $domain_ip"
        warn "Не совпадают! Let's Encrypt может отказать в сертификате."
        echo -ne "${YELLOW}Продолжить всё равно? [y/N]: ${RESET}"
        read -r ans
        [[ "${ans,,}" == "y" ]] || exit 1
    else
        ok "DNS OK: $domain → $domain_ip"
    fi
}

# ─── Зависимости ─────────────────────────────────────────────
install_deps() {
    info "Обновляю пакеты и ставлю зависимости..."
    apt-get update -qq
    apt-get install -y -qq curl wget unzip tar ufw openssl dnsutils 2>/dev/null || true

    export PATH="/usr/local/go/bin:$PATH"
    local go_ver go_major go_minor
    go_ver=$(go version 2>/dev/null | grep -oP 'go\K[\d.]+' || echo "0.0")
    go_major=$(echo "$go_ver" | cut -d. -f1)
    go_minor=$(echo "$go_ver" | cut -d. -f2)

    if [[ "$go_major" -lt 1 ]] || [[ "$go_major" -eq 1 && "$go_minor" -lt 21 ]]; then
        warn "Go $go_ver устарел, ставлю свежий..."
        local arch
        arch=$(dpkg --print-architecture)
        [[ "$arch" == "arm64" ]] || arch="amd64"
        local go_ver_pin="1.22.4"
        local go_url="https://go.dev/dl/go${go_ver_pin}.linux-${arch}.tar.gz"
        local go_sha256_amd64="ba79d4526102575196273416239cca418a651e049c2b099f3159db85e7bade7d"
        local go_sha256_arm64="a8e177c354d2e4a1b61020aca3c6f61bfba9a2e8f52c8dcef2b87abe86bd8fc0"
        local expected_sha
        [[ "$arch" == "arm64" ]] && expected_sha="$go_sha256_arm64" || expected_sha="$go_sha256_amd64"

        wget -q "$go_url" -O /tmp/go.tar.gz
        local actual_sha
        actual_sha=$(sha256sum /tmp/go.tar.gz | awk '{print $1}')
        if [[ "$actual_sha" != "$expected_sha" ]]; then
            err "SHA256 Go не совпадает! Возможная атака на цепочку поставок. Прерываю."
            rm -f /tmp/go.tar.gz
            exit 1
        fi
        ok "SHA256 Go подтверждён"
        rm -rf /usr/local/go
        tar -C /usr/local -xzf /tmp/go.tar.gz
        rm /tmp/go.tar.gz
        echo 'export PATH="/usr/local/go/bin:$PATH"' > /etc/profile.d/go.sh
    fi

    export PATH="/usr/local/go/bin:$PATH"
    ok "Зависимости готовы"
}

# ─── Сборка Caddy ────────────────────────────────────────────
build_caddy() {
    info "Собираю Caddy с forwardproxy (naive)..."
    info "Занимает 3-10 минут, не прерывай..."

    export PATH="/usr/local/go/bin:$PATH"
    export GOPATH="/root/go"
    export GOCACHE="/root/.cache/go-build"

    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

    "$GOPATH/bin/xcaddy" build \
        --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive \
        --output "$CADDY_BIN"

    chmod +x "$CADDY_BIN"
    ok "Caddy собран: $("$CADDY_BIN" version 2>/dev/null | head -1)"
}

# ─── Caddyfile ───────────────────────────────────────────────
write_caddyfile() {
    mkdir -p "$CADDY_DIR" "$WEBROOT" "$LOG_DIR"

    cat > "$WEBROOT/index.html" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Welcome</title></head>
<body><h1>It works!</h1></body>
</html>
HTMLEOF

    # Собираем блоки basic_auth
    local auth_blocks=""
    while IFS=: read -r u p; do
        [[ -z "$u" ]] && continue
        auth_blocks+="        basic_auth ${u} ${p}"$'\n'
    done < <(get_users)

    cat > "$CADDYFILE" <<EOF
{
    order forward_proxy before file_server
    log {
        output file ${LOG_DIR}/access.log {
            roll_size 50mb
            roll_keep 3
        }
    }
}

${DOMAIN}:443 {
    tls ${EMAIL}

    forward_proxy {
${auth_blocks}        hide_ip
        hide_via
        probe_resistance
    }

    file_server {
        root ${WEBROOT}
    }

    log {
        output file ${LOG_DIR}/naive.log {
            roll_size 20mb
            roll_keep 5
        }
    }
}
EOF

    chmod 600 "$CADDYFILE"
    ok "Caddyfile обновлён (пользователей: $(get_users | wc -l))"
}

# ─── systemd ─────────────────────────────────────────────────
write_service() {
    cat > "$CADDY_SERVICE" <<'EOF'
[Unit]
Description=Caddy NaiveProxy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=root
Group=root
ExecStart=/usr/local/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable caddy --quiet
    ok "systemd сервис настроен"
}

# ─── UFW ─────────────────────────────────────────────────────
setup_firewall() {
    command -v ufw &>/dev/null || return
    info "Настраиваю UFW..."
    ufw allow 80/tcp  comment 'NaiveProxy ACME'  >/dev/null 2>&1 || true
    ufw allow 443/tcp comment 'NaiveProxy HTTPS' >/dev/null 2>&1 || true
    ufw allow 443/udp comment 'NaiveProxy HTTP3' >/dev/null 2>&1 || true
    ok "UFW: открыты 80, 443/tcp, 443/udp"
}

# ─── BBR ─────────────────────────────────────────────────────
enable_bbr() {
    local current
    current=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')
    [[ "$current" == "bbr" ]] && { ok "BBR уже включён"; return; }

    echo -ne "${YELLOW}Включить TCP BBR для ускорения? [y/N]: ${RESET}"
    read -r ans
    if [[ "${ans,,}" == "y" ]]; then
        cat > /etc/sysctl.d/99-bbr.conf <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
        sysctl -p /etc/sysctl.d/99-bbr.conf >/dev/null 2>&1
        ok "BBR включён"
    fi
}

# ─── Бэкап ───────────────────────────────────────────────────
backup_config() {
    [[ -f "$CADDYFILE" ]] || return
    mkdir -p "$BACKUP_DIR"
    local ts; ts=$(date +%Y%m%d_%H%M%S)
    cp "$CADDYFILE" "$BACKUP_DIR/Caddyfile.$ts"
    ok "Бэкап → $BACKUP_DIR/Caddyfile.$ts"
}

# ─── Клиентский конфиг ───────────────────────────────────────
print_client_config() {
    load_config
    hr
    echo -e "${BOLD}${GREEN}  Клиентский конфиг NaiveProxy${RESET}"
    hr

    local first_user first_pass
    first_user=$(get_users | head -1 | cut -d: -f1)
    first_pass=$(get_users | head -1 | cut -d: -f2)

    if [[ -z "${first_user:-}" ]]; then
        warn "Нет пользователей. Добавь через меню → Пользователи."
        return
    fi

    echo -e "${CYAN}  URI:${RESET}"
    echo -e "  naive+https://${first_user}:${first_pass}@${DOMAIN}:443"
    echo
    echo -e "${CYAN}  JSON (naive-client):${RESET}"
    cat <<EOF
  {
    "listen": "socks://127.0.0.1:1080",
    "proxy": "https://${first_user}:${first_pass}@${DOMAIN}:443"
  }
EOF
    echo
    echo -e "${CYAN}  JSON (sing-box outbound):${RESET}"
    cat <<EOF
  {
    "type": "http",
    "tag": "naiveproxy-out",
    "server": "${DOMAIN}",
    "server_port": 443,
    "username": "${first_user}",
    "password": "${first_pass}",
    "tls": { "enabled": true, "server_name": "${DOMAIN}" }
  }
EOF

    local count; count=$(get_users | wc -l)
    if [[ $count -gt 1 ]]; then
        echo
        info "Все пользователи ($count):"
        while IFS=: read -r u p; do
            echo -e "  👤 ${BOLD}$u${RESET} : naive+https://${u}:${p}@${DOMAIN}:443"
        done < <(get_users)
    fi
    hr
}

# ─── Ввод параметров ─────────────────────────────────────────
prompt_params() {
    echo
    echo -e "${BOLD}Настройка NaiveProxy:${RESET}"
    echo

    while true; do
        echo -ne "${CYAN}Домен (например, proxy.example.com): ${RESET}"
        read -r DOMAIN
        # Валидация: только буквы, цифры, дефис, точка
        if [[ -n "$DOMAIN" && "$DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
            break
        fi
        err "Неверный формат домена. Только буквы, цифры, дефис, точка."
    done

    while true; do
        echo -ne "${CYAN}Email для TLS (Let's Encrypt): ${RESET}"
        read -r EMAIL
        [[ "$EMAIL" =~ ^[^@]+@[^@]+\.[^@]+$ ]] && break
        err "Введи корректный email"
    done

    echo -ne "${CYAN}Логин первого пользователя (Enter = naive): ${RESET}"
    read -r first_user
    first_user="${first_user:-naive}"

    echo -ne "${CYAN}Пароль (Enter = случайный): ${RESET}"
    read -r first_pass
    if [[ -z "$first_pass" ]]; then
        first_pass=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 20)
        info "Сгенерирован пароль: $first_pass"
    fi

    load_users
    echo "${first_user}:${first_pass}" > "$USERS_FILE"
    chmod 600 "$USERS_FILE"
}

# ─── УПРАВЛЕНИЕ ПОЛЬЗОВАТЕЛЯМИ ────────────────────────────────
cmd_users() {
    load_users

    while true; do
        hr
        echo -e "${BOLD}  Управление пользователями${RESET}"
        hr
        echo -e "  ${BOLD}1)${RESET} Список пользователей"
        echo -e "  ${BOLD}2)${RESET} Добавить пользователя"
        echo -e "  ${BOLD}3)${RESET} Удалить пользователя"
        echo -e "  ${BOLD}4)${RESET} Сменить пароль"
        echo -e "  ${BOLD}0)${RESET} Назад"
        hr
        echo -ne "${CYAN}Выбор: ${RESET}"
        read -r choice; echo

        case "$choice" in
            1)
                local count=0
                while IFS=: read -r u p; do
                    ((count++))
                    echo -e "  ${count}. ${BOLD}${u}${RESET} : $p"
                done < <(get_users)
                [[ $count -eq 0 ]] && warn "Нет пользователей"
                echo -e "  Итого: $count"
                ;;
            2)
                echo -ne "${CYAN}Новый логин: ${RESET}"; read -r new_user
                [[ -z "$new_user" ]] && { err "Логин не может быть пустым"; continue; }
                # Валидация: только буквы, цифры, дефис, подчёркивание (защита от sed-инъекции)
                if [[ ! "$new_user" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                    err "Логин содержит недопустимые символы. Только: a-z A-Z 0-9 _ -"
                    continue
                fi
                if get_users | grep -q "^${new_user}:"; then
                    err "Пользователь $new_user уже существует"
                    continue
                fi
                echo -ne "${CYAN}Пароль (Enter = случайный): ${RESET}"; read -r new_pass
                if [[ -z "$new_pass" ]]; then
                    new_pass=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 20)
                    info "Сгенерирован пароль: $new_pass"
                fi
                echo "${new_user}:${new_pass}" >> "$USERS_FILE"
                backup_config
                write_caddyfile
                systemctl reload caddy 2>/dev/null || systemctl restart caddy
                ok "Пользователь $new_user добавлен"
                tg_send "👤 <b>Новый пользователь NaiveProxy</b>
🔑 Логин: <code>${new_user}</code>
🕐 $(date '+%Y-%m-%d %H:%M:%S')"
                ;;
            3)
                echo -ne "${CYAN}Логин для удаления: ${RESET}"; read -r del_user
                if ! get_users | grep -q "^${del_user}:"; then
                    err "Пользователь $del_user не найден"
                    continue
                fi
                backup_config
                sed -i "/^${del_user}:/d" "$USERS_FILE"
                write_caddyfile
                systemctl reload caddy 2>/dev/null || systemctl restart caddy
                ok "Пользователь $del_user удалён"
                tg_send "🗑 <b>Пользователь удалён: ${del_user}</b>
🕐 $(date '+%Y-%m-%d %H:%M:%S')"
                ;;
            4)
                echo -ne "${CYAN}Логин: ${RESET}"; read -r chg_user
                if ! get_users | grep -q "^${chg_user}:"; then
                    err "Пользователь $chg_user не найден"; continue
                fi
                echo -ne "${CYAN}Новый пароль (Enter = случайный): ${RESET}"; read -r chg_pass
                if [[ -z "$chg_pass" ]]; then
                    chg_pass=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 20)
                    info "Сгенерирован пароль: $chg_pass"
                fi
                backup_config
                sed -i "s/^${chg_user}:.*/${chg_user}:${chg_pass}/" "$USERS_FILE"
                write_caddyfile
                systemctl reload caddy 2>/dev/null || systemctl restart caddy
                ok "Пароль $chg_user изменён"
                ;;
            0) break ;;
            *) warn "Неверный выбор" ;;
        esac

        echo -ne "${YELLOW}Enter для продолжения...${RESET}"; read -r
    done
}

# ─── МОНИТОРИНГ ──────────────────────────────────────────────
cmd_monitor() {
    hr
    echo -e "${BOLD}  Мониторинг и статистика${RESET}"
    hr

    if systemctl is-active --quiet caddy 2>/dev/null; then
        echo -e "  Caddy:     ${GREEN}● работает${RESET}"
    else
        echo -e "  Caddy:     ${RED}● остановлен${RESET}"
    fi

    local uptime_str
    uptime_str=$(systemctl show caddy --property=ActiveEnterTimestamp 2>/dev/null \
        | cut -d= -f2 | xargs -I{} date -d "{}" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "н/д")
    echo -e "  Запущен:   $uptime_str"
    echo -e "  Caddy:     $("$CADDY_BIN" version 2>/dev/null | head -1 | awk '{print $1}' || echo н/д)"
    echo -e "  Юзеров:    $(get_users | wc -l)"

    local iface
    iface=$(ip route | awk '/default/{print $5}' | head -1)
    if [[ -n "$iface" ]]; then
        local rx tx
        rx=$(cat /sys/class/net/"$iface"/statistics/rx_bytes 2>/dev/null || echo 0)
        tx=$(cat /sys/class/net/"$iface"/statistics/tx_bytes 2>/dev/null || echo 0)
        echo
        echo -e "  ${BOLD}Трафик ($iface, с ребута):${RESET}"
        echo -e "  ⬇ Входящий:  $(numfmt --to=iec "$rx" 2>/dev/null || echo $rx)"
        echo -e "  ⬆ Исходящий: $(numfmt --to=iec "$tx" 2>/dev/null || echo $tx)"
    fi

    echo
    echo -e "  ${BOLD}Ресурсы:${RESET}"
    echo -e "  RAM:    $(free -h | awk '/Mem:/{print $3" / "$2}')"
    echo -e "  Диск:   $(df -h / | awk 'NR==2{print $3" / "$2" ("$5")"}')"
    echo -e "  Uptime: $(uptime -p)"

    load_config
    if [[ -n "${DOMAIN:-}" ]]; then
        echo
        info "Проверяю доступность https://${DOMAIN}..."
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://${DOMAIN}" 2>/dev/null || echo "000")
        if [[ "$http_code" =~ ^[23] ]]; then
            ok "https://${DOMAIN} доступен (HTTP $http_code)"
        else
            warn "https://${DOMAIN} — HTTP $http_code"
        fi
    fi

    echo
    echo -ne "${YELLOW}Отправить статистику в Telegram? [y/N]: ${RESET}"
    read -r ans
    [[ "${ans,,}" == "y" ]] && tg_send_stats && ok "Отправлено в Telegram"
    hr
}

# ─── УСТАНОВКА ───────────────────────────────────────────────
cmd_install() {
    hr
    echo -e "${BOLD}  Установка NaiveProxy v${VERSION}${RESET}"
    hr

    if check_installed; then
        warn "NaiveProxy уже установлен."
        echo -ne "${YELLOW}Переустановить? [y/N]: ${RESET}"
        read -r ans
        [[ "${ans,,}" == "y" ]] || return
        systemctl stop caddy 2>/dev/null || true
    fi

    prompt_params
    check_domain "$DOMAIN"
    install_deps
    build_caddy
    write_caddyfile
    write_service
    setup_firewall
    enable_bbr

    echo
    echo -ne "${YELLOW}Настроить Telegram-уведомления? [y/N]: ${RESET}"
    read -r ans
    [[ "${ans,,}" == "y" ]] && setup_telegram

    save_config
    install_monitor

    info "Запускаю Caddy..."
    systemctl restart caddy
    sleep 3

    if systemctl is-active --quiet caddy; then
        ok "Caddy запущен успешно"
        tg_alert_up
    else
        err "Caddy не запустился. Лог:"
        journalctl -u caddy -n 30 --no-pager
        exit 1
    fi

    print_client_config
}

# ─── СТАТУС ──────────────────────────────────────────────────
cmd_status() {
    hr
    echo -e "${BOLD}  Статус NaiveProxy${RESET}"
    hr

    systemctl is-active --quiet caddy 2>/dev/null \
        && ok "Caddy: ${GREEN}работает${RESET}" \
        || err "Caddy: ${RED}не работает${RESET}"
    systemctl is-enabled --quiet caddy 2>/dev/null \
        && ok "Автозапуск: включён" \
        || warn "Автозапуск: выключен"

    load_config
    [[ -n "${DOMAIN:-}" ]] && echo -e "\n  Домен:   $DOMAIN"
    echo -e "  Юзеров: $(get_users | wc -l)"
    echo
    info "Последние 10 строк лога:"
    journalctl -u caddy -n 10 --no-pager 2>/dev/null || true
    hr
}

# ─── ПЕРЕЗАПУСК ──────────────────────────────────────────────
cmd_restart() {
    info "Перезапускаю Caddy..."
    systemctl restart caddy
    sleep 2
    if systemctl is-active --quiet caddy; then
        ok "Caddy перезапущен"
        load_config; tg_alert_up
    else
        err "Caddy не запустился:"
        journalctl -u caddy -n 20 --no-pager
    fi
}

# ─── ОБНОВЛЕНИЕ ──────────────────────────────────────────────
cmd_update() {
    hr
    echo -e "${BOLD}  Обновление Caddy${RESET}"
    hr

    check_installed || { err "NaiveProxy не установлен"; return 1; }

    local old_ver
    old_ver=$("$CADDY_BIN" version 2>/dev/null | head -1 || echo "unknown")
    info "Текущая версия: $old_ver"

    backup_config
    systemctl stop caddy
    build_caddy
    systemctl start caddy

    local new_ver
    new_ver=$("$CADDY_BIN" version 2>/dev/null | head -1 || echo "unknown")
    ok "Обновлено: $old_ver → $new_ver"
    load_config; tg_alert_updated "$old_ver" "$new_ver"
}

# ─── УДАЛЕНИЕ ────────────────────────────────────────────────
cmd_remove() {
    hr
    echo -e "${BOLD}${RED}  Удаление NaiveProxy${RESET}"
    hr
    echo -ne "${RED}Удалить всё? [y/N]: ${RESET}"
    read -r ans
    [[ "${ans,,}" == "y" ]] || return

    systemctl stop caddy    2>/dev/null || true
    systemctl disable caddy 2>/dev/null || true
    rm -f "$CADDY_SERVICE" "$CADDY_BIN" "$CADDYFILE"
    rm -rf "$CONFIG_DIR"
    systemctl daemon-reload

    ufw delete allow 80/tcp  >/dev/null 2>&1 || true
    ufw delete allow 443/tcp >/dev/null 2>&1 || true
    ufw delete allow 443/udp >/dev/null 2>&1 || true

    ( crontab -l 2>/dev/null | grep -v "naiveproxy\|monitor\.sh" || true ) | crontab -

    ok "NaiveProxy удалён"
}

# ─── ЛОГИ ────────────────────────────────────────────────────
cmd_logs() {
    echo -e "${BOLD}Лог Caddy (Ctrl+C для выхода):${RESET}"
    journalctl -u caddy -n 50 -f
}

# ─── МЕНЮ ────────────────────────────────────────────────────
show_menu() {
    clear
    load_config

    local status_str="${YELLOW}● не установлен${RESET}"
    if check_installed; then
        systemctl is-active --quiet caddy 2>/dev/null \
            && status_str="${GREEN}● работает${RESET}" \
            || status_str="${RED}● остановлен${RESET}"
    fi

    local tg_str="${RED}не настроен${RESET}"
    [[ -n "${TG_TOKEN:-}" ]] && tg_str="${GREEN}подключён${RESET}"

    hr
    echo -e "${BOLD}${CYAN}   NaiveProxy Manager v${VERSION}${RESET}"
    echo -e "   Статус: ${status_str}  |  Домен: ${CYAN}${DOMAIN:-не задан}${RESET}"
    echo -e "   Telegram: ${tg_str}  |  Юзеров: $(get_users | wc -l)"
    hr
    echo -e "   ${BOLD}1)${RESET}  Установить NaiveProxy"
    echo -e "   ${BOLD}2)${RESET}  Статус"
    echo -e "   ${BOLD}3)${RESET}  Клиентский конфиг"
    echo -e "   ${BOLD}4)${RESET}  Управление пользователями"
    echo -e "   ${BOLD}5)${RESET}  Мониторинг и статистика"
    echo -e "   ${BOLD}6)${RESET}  Настройка Telegram"
    echo -e "   ${BOLD}7)${RESET}  Перезапустить Caddy"
    echo -e "   ${BOLD}8)${RESET}  Обновить Caddy"
    echo -e "   ${BOLD}9)${RESET}  Логи"
    echo -e "   ${BOLD}10)${RESET} Удалить NaiveProxy"
    echo -e "   ${BOLD}0)${RESET}  Выход"
    hr
    echo -ne "${CYAN}Выбор [0-10]: ${RESET}"
}

# ─── MAIN ────────────────────────────────────────────────────
main() {
    check_root
    check_os

    if [[ $# -gt 0 ]]; then
        load_config; load_users
        case "$1" in
            install)   cmd_install ;;
            status)    cmd_status ;;
            config)    print_client_config ;;
            restart)   cmd_restart ;;
            update)    cmd_update ;;
            remove)    cmd_remove ;;
            logs)      cmd_logs ;;
            monitor)   cmd_monitor ;;
            users)     cmd_users ;;
            tg-stats)  tg_send_stats; ok "Отправлено" ;;
            *) err "Неизвестная команда: $1"
               echo "Доступные: install status config restart update remove logs monitor users tg-stats"
               exit 1 ;;
        esac
        exit 0
    fi

    while true; do
        show_menu
        read -r choice; echo
        load_config; load_users
        case "$choice" in
            1)  cmd_install ;;
            2)  cmd_status ;;
            3)  print_client_config ;;
            4)  cmd_users ;;
            5)  cmd_monitor ;;
            6)  setup_telegram ;;
            7)  cmd_restart ;;
            8)  cmd_update ;;
            9)  cmd_logs ;;
            10) cmd_remove ;;
            0)  echo -e "${GREEN}Пока!${RESET}"; exit 0 ;;
            *)  warn "Неверный выбор" ;;
        esac
        echo
        echo -ne "${YELLOW}Нажми Enter чтобы вернуться в меню...${RESET}"
        read -r
    done
}

main "$@"
