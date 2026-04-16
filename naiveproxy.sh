#!/bin/bash
# ============================================================
#   NaiveProxy Manager — by ivanstudiya-cpu
#   Стек: Caddy + forwardproxy (klzgrad/forwardproxy@naive)
#   ОС: Ubuntu 20.04/22.04/24.04
# ============================================================

set -euo pipefail

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
LOG_DIR="/var/log/caddy"
BACKUP_DIR="/etc/naiveproxy/backups"

# ─── Версия Caddy (xcaddy build — указываем тег) ─────────────
CADDY_VERSION="latest"

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

# ─── Загрузка конфига ────────────────────────────────────────
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    fi
}

save_config() {
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" <<EOF
DOMAIN="${DOMAIN}"
NP_USER="${NP_USER}"
NP_PASS="${NP_PASS}"
EMAIL="${EMAIL}"
INSTALLED_AT="$(date '+%Y-%m-%d %H:%M:%S')"
EOF
    chmod 600 "$CONFIG_FILE"
}

# ─── Проверка домена ─────────────────────────────────────────
check_domain() {
    local domain="$1"
    info "Проверяю что домен $domain указывает на этот сервер..."

    local server_ip
    server_ip=$(curl -s4 https://ifconfig.me 2>/dev/null || curl -s4 https://api.ipify.org 2>/dev/null)

    local domain_ip
    domain_ip=$(getent hosts "$domain" 2>/dev/null | awk '{print $1}' | head -1)

    if [[ -z "$domain_ip" ]]; then
        err "Домен $domain не резолвится. Проверь DNS."
        exit 1
    fi

    if [[ "$server_ip" != "$domain_ip" ]]; then
        warn "IP сервера: $server_ip"
        warn "IP домена:  $domain_ip"
        warn "Они не совпадают! Caddy не сможет получить TLS-сертификат."
        echo -ne "${YELLOW}Продолжить всё равно? [y/N]: ${RESET}"
        read -r ans
        [[ "${ans,,}" == "y" ]] || exit 1
    else
        ok "Домен $domain → $domain_ip — всё ок"
    fi
}

# ─── Зависимости ─────────────────────────────────────────────
install_deps() {
    info "Обновляю пакеты и ставлю зависимости..."
    apt-get update -qq
    apt-get install -y -qq \
        curl wget unzip tar \
        golang-go \
        ufw \
        openssl \
        dnsutils \
        2>/dev/null || true

    # go может быть старый в репах — ставим свежий если нужно
    local go_ver
    go_ver=$(go version 2>/dev/null | grep -oP 'go\K[\d.]+' || echo "0")
    local go_major go_minor
    go_major=$(echo "$go_ver" | cut -d. -f1)
    go_minor=$(echo "$go_ver" | cut -d. -f2)

    if [[ "$go_major" -lt 1 ]] || [[ "$go_major" -eq 1 && "$go_minor" -lt 21 ]]; then
        warn "Go $go_ver слишком старый, ставлю свежий..."
        local go_latest="1.22.4"
        local arch
        arch=$(dpkg --print-architecture)
        [[ "$arch" == "amd64" ]] && arch="amd64" || arch="arm64"
        wget -q "https://go.dev/dl/go${go_latest}.linux-${arch}.tar.gz" -O /tmp/go.tar.gz
        rm -rf /usr/local/go
        tar -C /usr/local -xzf /tmp/go.tar.gz
        rm /tmp/go.tar.gz
        export PATH="/usr/local/go/bin:$PATH"
        echo 'export PATH="/usr/local/go/bin:$PATH"' >> /etc/profile.d/go.sh
    fi

    ok "Зависимости установлены"
}

# ─── Сборка Caddy с forwardproxy ─────────────────────────────
build_caddy() {
    info "Собираю Caddy с модулем forwardproxy (naive)..."
    info "Это занимает 3-7 минут, будь терпелив..."

    export PATH="/usr/local/go/bin:$PATH"
    export GOPATH="/root/go"
    export GOCACHE="/root/.cache/go-build"

    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

    "$GOPATH/bin/xcaddy" build \
        --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive \
        --output "$CADDY_BIN"

    chmod +x "$CADDY_BIN"

    local caddy_ver
    caddy_ver=$("$CADDY_BIN" version 2>/dev/null | head -1 || echo "unknown")
    ok "Caddy собран: $caddy_ver"
}

# ─── Генерация Caddyfile ──────────────────────────────────────
write_caddyfile() {
    mkdir -p "$CADDY_DIR" "$WEBROOT" "$LOG_DIR"

    # Создаём заглушку-сайт (чтобы probe-атаки видели живой сайт)
    cat > "$WEBROOT/index.html" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Welcome</title></head>
<body><h1>It works!</h1></body>
</html>
HTMLEOF

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
        basic_auth ${NP_USER} ${NP_PASS}
        hide_ip
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
    ok "Caddyfile записан"
}

# ─── systemd сервис ───────────────────────────────────────────
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

# ─── UFW ──────────────────────────────────────────────────────
setup_firewall() {
    if command -v ufw &>/dev/null; then
        info "Настраиваю UFW..."
        ufw allow 80/tcp  comment 'NaiveProxy HTTP (ACME)' --force >/dev/null 2>&1 || true
        ufw allow 443/tcp comment 'NaiveProxy HTTPS'       --force >/dev/null 2>&1 || true
        ufw allow 443/udp comment 'NaiveProxy HTTP/3'      --force >/dev/null 2>&1 || true
        ok "UFW: открыты порты 80, 443 (tcp+udp)"
    else
        warn "UFW не найден, пропускаю"
    fi
}

# ─── BBR ──────────────────────────────────────────────────────
enable_bbr() {
    local current_cc
    current_cc=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')
    if [[ "$current_cc" == "bbr" ]]; then
        ok "BBR уже включён"
        return
    fi

    echo -ne "${YELLOW}Включить TCP BBR для ускорения? [y/N]: ${RESET}"
    read -r ans
    if [[ "${ans,,}" == "y" ]]; then
        cat >> /etc/sysctl.d/99-bbr.conf <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
        sysctl -p /etc/sysctl.d/99-bbr.conf >/dev/null 2>&1
        ok "BBR включён"
    fi
}

# ─── Генерация клиентского конфига ───────────────────────────
print_client_config() {
    local domain="${DOMAIN}"
    local user="${NP_USER}"
    local pass="${NP_PASS}"

    hr
    echo -e "${BOLD}${GREEN}  NaiveProxy установлен!${RESET}"
    hr
    echo -e "${BOLD}  Клиентский конфиг (v2rayN / NekoBox / sing-box):${RESET}"
    echo
    echo -e "${CYAN}  URI:${RESET}"
    echo -e "  naive+https://${user}:${pass}@${domain}:443"
    echo
    echo -e "${CYAN}  JSON (naive client):${RESET}"
    cat <<JSONEOF
  {
    "listen": "socks://127.0.0.1:1080",
    "proxy": "https://${user}:${pass}@${domain}:443"
  }
JSONEOF
    echo
    echo -e "${CYAN}  JSON (sing-box outbound):${RESET}"
    cat <<JSONEOF
  {
    "type": "http",
    "tag": "naiveproxy-out",
    "server": "${domain}",
    "server_port": 443,
    "username": "${user}",
    "password": "${pass}",
    "tls": {
      "enabled": true,
      "server_name": "${domain}"
    }
  }
JSONEOF
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
        [[ -n "$DOMAIN" ]] && break
        err "Домен не может быть пустым"
    done

    while true; do
        echo -ne "${CYAN}Email для TLS (Let's Encrypt): ${RESET}"
        read -r EMAIL
        [[ "$EMAIL" =~ ^[^@]+@[^@]+\.[^@]+$ ]] && break
        err "Введи корректный email"
    done

    echo -ne "${CYAN}Логин (Enter = naive): ${RESET}"
    read -r NP_USER
    NP_USER="${NP_USER:-naive}"

    echo -ne "${CYAN}Пароль (Enter = случайный): ${RESET}"
    read -r NP_PASS
    if [[ -z "$NP_PASS" ]]; then
        NP_PASS=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 20)
        info "Сгенерирован пароль: $NP_PASS"
    fi
}

# ─── Бэкап конфига ───────────────────────────────────────────
backup_config() {
    if [[ -f "$CADDYFILE" ]]; then
        mkdir -p "$BACKUP_DIR"
        local ts
        ts=$(date +%Y%m%d_%H%M%S)
        cp "$CADDYFILE" "$BACKUP_DIR/Caddyfile.$ts"
        ok "Бэкап Caddyfile → $BACKUP_DIR/Caddyfile.$ts"
    fi
}

# ─── УСТАНОВКА ────────────────────────────────────────────────
cmd_install() {
    hr
    echo -e "${BOLD}  Установка NaiveProxy${RESET}"
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
    save_config

    info "Запускаю Caddy..."
    systemctl restart caddy

    sleep 3
    if systemctl is-active --quiet caddy; then
        ok "Caddy запущен успешно"
    else
        err "Caddy не запустился. Лог:"
        journalctl -u caddy -n 30 --no-pager
        exit 1
    fi

    print_client_config
}

# ─── СТАТУС ───────────────────────────────────────────────────
cmd_status() {
    hr
    echo -e "${BOLD}  Статус NaiveProxy${RESET}"
    hr

    if systemctl is-active --quiet caddy 2>/dev/null; then
        ok "Caddy: ${GREEN}работает${RESET}"
    else
        err "Caddy: ${RED}не работает${RESET}"
    fi

    if systemctl is-enabled --quiet caddy 2>/dev/null; then
        ok "Автозапуск: включён"
    else
        warn "Автозапуск: выключен"
    fi

    load_config
    if [[ -n "${DOMAIN:-}" ]]; then
        echo
        echo -e "  ${BOLD}Домен:${RESET}    $DOMAIN"
        echo -e "  ${BOLD}Логин:${RESET}    $NP_USER"
        echo -e "  ${BOLD}Пароль:${RESET}   $NP_PASS"
        echo -e "  ${BOLD}Email:${RESET}    $EMAIL"
        [[ -n "${INSTALLED_AT:-}" ]] && \
            echo -e "  ${BOLD}Установлен:${RESET} $INSTALLED_AT"
    fi

    echo
    info "Последние 10 строк лога:"
    journalctl -u caddy -n 10 --no-pager 2>/dev/null || true
    hr
}

# ─── СМЕНА ПАРОЛЯ ─────────────────────────────────────────────
cmd_change_pass() {
    hr
    echo -e "${BOLD}  Смена пароля${RESET}"
    hr

    if ! check_installed; then
        err "NaiveProxy не установлен"
        return 1
    fi

    load_config
    backup_config

    echo -ne "${CYAN}Новый пароль (Enter = случайный): ${RESET}"
    read -r new_pass
    if [[ -z "$new_pass" ]]; then
        new_pass=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 20)
        info "Сгенерирован пароль: $new_pass"
    fi

    NP_PASS="$new_pass"
    write_caddyfile
    save_config
    systemctl reload caddy 2>/dev/null || systemctl restart caddy
    ok "Пароль изменён"
    print_client_config
}

# ─── ПОКАЗАТЬ КОНФИГ ──────────────────────────────────────────
cmd_config() {
    load_config
    if [[ -z "${DOMAIN:-}" ]]; then
        err "NaiveProxy не установлен или конфиг не найден"
        return 1
    fi
    print_client_config
}

# ─── ПЕРЕЗАПУСК ───────────────────────────────────────────────
cmd_restart() {
    info "Перезапускаю Caddy..."
    systemctl restart caddy
    sleep 2
    if systemctl is-active --quiet caddy; then
        ok "Caddy перезапущен"
    else
        err "Caddy не запустился:"
        journalctl -u caddy -n 20 --no-pager
    fi
}

# ─── ОБНОВЛЕНИЕ CADDY ─────────────────────────────────────────
cmd_update() {
    hr
    echo -e "${BOLD}  Обновление Caddy${RESET}"
    hr

    if ! check_installed; then
        err "NaiveProxy не установлен"
        return 1
    fi

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
}

# ─── УДАЛЕНИЕ ─────────────────────────────────────────────────
cmd_remove() {
    hr
    echo -e "${BOLD}${RED}  Удаление NaiveProxy${RESET}"
    hr

    echo -ne "${RED}Ты уверен? Это удалит Caddy и все конфиги [y/N]: ${RESET}"
    read -r ans
    [[ "${ans,,}" == "y" ]] || return

    systemctl stop caddy 2>/dev/null || true
    systemctl disable caddy 2>/dev/null || true
    rm -f "$CADDY_SERVICE"
    rm -f "$CADDY_BIN"
    rm -f "$CADDYFILE"
    rm -rf "$CONFIG_DIR"
    systemctl daemon-reload

    # UFW — убираем правила
    ufw delete allow 80/tcp >/dev/null 2>&1 || true
    ufw delete allow 443/tcp >/dev/null 2>&1 || true
    ufw delete allow 443/udp >/dev/null 2>&1 || true

    ok "NaiveProxy удалён"
}

# ─── ЛОГИ ────────────────────────────────────────────────────
cmd_logs() {
    echo -e "${BOLD}Лог Caddy (последние 50 строк, Ctrl+C для выхода):${RESET}"
    journalctl -u caddy -n 50 -f
}

# ─── МЕНЮ ────────────────────────────────────────────────────
show_menu() {
    clear
    hr
    echo -e "${BOLD}${CYAN}   NaiveProxy Manager${RESET}"
    echo -e "   Caddy + forwardproxy (klzgrad/naive)"
    hr
    echo -e "   ${BOLD}1)${RESET} Установить NaiveProxy"
    echo -e "   ${BOLD}2)${RESET} Статус"
    echo -e "   ${BOLD}3)${RESET} Показать клиентский конфиг"
    echo -e "   ${BOLD}4)${RESET} Сменить пароль"
    echo -e "   ${BOLD}5)${RESET} Перезапустить Caddy"
    echo -e "   ${BOLD}6)${RESET} Обновить Caddy"
    echo -e "   ${BOLD}7)${RESET} Просмотр логов"
    echo -e "   ${BOLD}8)${RESET} Удалить NaiveProxy"
    echo -e "   ${BOLD}0)${RESET} Выход"
    hr
    echo -ne "${CYAN}Выбор [0-8]: ${RESET}"
}

# ─── MAIN ────────────────────────────────────────────────────
main() {
    check_root
    check_os

    # Поддержка аргументов: bash naiveproxy.sh install
    if [[ $# -gt 0 ]]; then
        case "$1" in
            install) cmd_install ;;
            status)  cmd_status ;;
            config)  cmd_config ;;
            restart) cmd_restart ;;
            update)  cmd_update ;;
            remove)  cmd_remove ;;
            logs)    cmd_logs ;;
            *) err "Неизвестная команда: $1"; exit 1 ;;
        esac
        exit 0
    fi

    # Интерактивное меню
    while true; do
        show_menu
        read -r choice
        echo
        case "$choice" in
            1) cmd_install ;;
            2) cmd_status ;;
            3) cmd_config ;;
            4) cmd_change_pass ;;
            5) cmd_restart ;;
            6) cmd_update ;;
            7) cmd_logs ;;
            8) cmd_remove ;;
            0) echo -e "${GREEN}Пока!${RESET}"; exit 0 ;;
            *) warn "Неверный выбор" ;;
        esac
        echo
        echo -ne "${YELLOW}Нажми Enter чтобы вернуться в меню...${RESET}"
        read -r
    done
}

main "$@"
