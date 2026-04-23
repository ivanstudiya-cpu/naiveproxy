#!/bin/bash
# ============================================================
#   NaiveProxy Manager v3.2.0 — by ivanstudiya-cpu
#   Стек: Caddy 2 + klzgrad/forwardproxy@naive
#   ОС: Ubuntu 20.04 / 22.04 / 24.04
#   GitHub: https://github.com/ivanstudiya-cpu/naiveproxy
# ============================================================

set -euo pipefail

VERSION="3.2.0"

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
SSH_HARDENING_DONE="/etc/naiveproxy/.ssh_hardened"
SYSUPDATE_DONE="/etc/naiveproxy/.sysupdate_done"


# ══════════════════════════════════════════════════════════════
#   БЛОК 1: ОБНОВЛЕНИЕ СИСТЕМЫ
# ══════════════════════════════════════════════════════════════

cmd_sysupdate() {
    hr
    echo -e "${BOLD}  Обновление системы${RESET}"
    hr
    # Загружаем конфиг для Telegram (может вызываться до основного load_config)
    load_config 2>/dev/null || true

    info "Обновляю списки пакетов..."
    apt-get update -q

    info "Устанавливаю обновления пакетов..."
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -q         -o Dpkg::Options::="--force-confdef"         -o Dpkg::Options::="--force-confold"

    info "Чищу ненужные пакеты..."
    apt-get autoremove -y -q
    apt-get autoclean -q

    # Ставим и настраиваем автообновления безопасности
    info "Настраиваю автоматические обновления безопасности..."
    apt-get install -y -q unattended-upgrades apt-listchanges

    cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::Package-Blacklist {};
Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:30";
EOF

    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

    systemctl enable unattended-upgrades --quiet 2>/dev/null || true
    systemctl restart unattended-upgrades 2>/dev/null || true

    # Проверяем нужен ли ребут
    if [[ -f /var/run/reboot-required ]]; then
        warn "Требуется перезагрузка сервера для применения обновлений ядра!"
        echo -ne "${YELLOW}Перезагрузить сейчас? [y/N]: ${RESET}"
        read -r ans
        if [[ "${ans,,}" == "y" ]]; then
            ok "Перезагружаю через 5 секунд..."
            sleep 5
            reboot
        else
            warn "Не забудь перезагрузить сервер позже: reboot"
        fi
    fi

    # Маркер что обновление выполнено
    mkdir -p "$CONFIG_DIR"
    date '+%Y-%m-%d %H:%M:%S' > "$SYSUPDATE_DONE"

    ok "Система обновлена"
    ok "Автообновления безопасности: включены (ежедневно)"
    tg_send "🔄 <b>Система обновлена</b>
🖥 Сервер: <code>$(hostname)</code>
🕐 $(date '+%Y-%m-%d %H:%M:%S')
🛡 Автообновления безопасности: включены"
}

# ══════════════════════════════════════════════════════════════
#   БЛОК 2: SSH HARDENING
# ══════════════════════════════════════════════════════════════

cmd_ssh_hardening() {
    hr
    echo -e "${BOLD}  SSH Hardening${RESET}"
    hr

    local sshd_config="/etc/ssh/sshd_config"
    local current_port
    current_port=$(grep -E "^Port " "$sshd_config" 2>/dev/null | awk '{print $2}' || echo "22")

    echo -e "  Текущий SSH порт: ${CYAN}${current_port}${RESET}"
    echo

    # ── Шаг 1: Создание нового пользователя ──────────────────
    hr
    echo -e "${BOLD}  Шаг 1: Новый sudo-пользователь${RESET}"
    hr

    local new_user=""
    while true; do
        echo -ne "${CYAN}Имя нового пользователя (Enter = пропустить): ${RESET}"
        read -r new_user
        if [[ -z "$new_user" ]]; then
            warn "Пропускаю создание пользователя"
            break
        fi
        if [[ ! "$new_user" =~ ^[a-z][a-z0-9_-]{2,31}$ ]]; then
            err "Только строчные буквы, цифры, _, - (3-32 символа, начинается с буквы)"
            continue
        fi
        if id "$new_user" &>/dev/null; then
            warn "Пользователь $new_user уже существует"
            break
        fi

        # Создаём пользователя
        useradd -m -s /bin/bash "$new_user"
        usermod -aG sudo "$new_user"

        # Пароль
        echo -ne "${CYAN}Пароль для $new_user (Enter = сгенерировать): ${RESET}"
        read -r user_pass
        if [[ -z "$user_pass" ]]; then
            user_pass=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 20)
            info "Сгенерирован пароль: ${BOLD}${user_pass}${RESET}"
            info "СОХРАНИ ЕГО СЕЙЧАС!"
        fi
        printf "%s:%s" "${new_user}" "${user_pass}" | chpasswd
        ok "Пользователь ${new_user} создан с правами sudo"
        break
    done

    # ── Шаг 2: SSH-ключ ──────────────────────────────────────
    hr
    echo -e "${BOLD}  Шаг 2: SSH-ключ (ED25519)${RESET}"
    hr

    local target_user="${new_user:-root}"
    local target_home
    target_home=$(getent passwd "$target_user" | cut -d: -f6)
    local ssh_dir="${target_home}/.ssh"
    local auth_keys="${ssh_dir}/authorized_keys"

    if [[ -f "$auth_keys" ]] && grep -q "ssh-" "$auth_keys" 2>/dev/null; then
        ok "SSH-ключ уже настроен для ${target_user}"
    else
        info "Генерирую ED25519 ключ для ${target_user}..."
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"

        # Генерируем ключ
        ssh-keygen -t ed25519 -f "${ssh_dir}/id_ed25519_server" -N "" -C "naiveproxy-server-$(date +%Y%m%d)" -q
        cat "${ssh_dir}/id_ed25519_server.pub" >> "$auth_keys"
        chmod 600 "$auth_keys"
        [[ "$target_user" != "root" ]] && chown -R "${target_user}:${target_user}" "$ssh_dir"

        echo
        echo -e "${RED}╔══════════════════════════════════════════════════════╗${RESET}"
        echo -e "${RED}║  ПРИВАТНЫЙ КЛЮЧ — СКОПИРУЙ И СОХРАНИ ПРЯМО СЕЙЧАС  ║${RESET}"
        echo -e "${RED}╚══════════════════════════════════════════════════════╝${RESET}"
        cat "${ssh_dir}/id_ed25519_server"
        echo -e "${RED}══════════════════════════════════════════════════════${RESET}"
        echo
        warn "Сохрани этот ключ в файл: id_naiveproxy (на своём компе)"
        warn "Подключение: ssh -i id_naiveproxy -p [НОВЫЙ_ПОРТ] ${target_user}@$(curl -s4 --max-time 5 https://ifconfig.me 2>/dev/null || echo YOUR_IP)"
        echo
        echo -ne "${YELLOW}Ты сохранил ключ? [yes]: ${RESET}"
        read -r confirm
        if [[ "${confirm,,}" != "yes" && "${confirm,,}" != "y" ]]; then
            warn "Пожалуйста сохрани ключ перед продолжением!"
            echo -ne "${YELLOW}Продолжить всё равно? [y/N]: ${RESET}"
            read -r force
            [[ "${force,,}" == "y" ]] || return 1
        fi
        ok "SSH-ключ сгенерирован и добавлен в authorized_keys"
    fi

    # ── Шаг 3: Смена SSH порта ────────────────────────────────
    hr
    echo -e "${BOLD}  Шаг 3: Смена SSH порта${RESET}"
    hr

    local new_ssh_port=""
    echo -e "  Текущий порт: ${CYAN}${current_port}${RESET}"
    echo -e "  ${BOLD}1)${RESET} Ввести вручную"
    echo -e "  ${BOLD}2)${RESET} Случайный (49000-65000)"
    echo -e "  ${BOLD}0)${RESET} Оставить ${current_port}"
    echo -ne "${CYAN}Выбор: ${RESET}"
    read -r port_choice

    case "$port_choice" in
        1)
            while true; do
                echo -ne "${CYAN}Новый SSH порт (1024-65535): ${RESET}"
                read -r new_ssh_port
                if [[ "$new_ssh_port" =~ ^[0-9]+$ ]] &&                    [[ "$new_ssh_port" -ge 1024 ]] &&                    [[ "$new_ssh_port" -le 65535 ]]; then
                    break
                fi
                err "Неверный порт. Введи число от 1024 до 65535"
            done
            ;;
        2)
            # Генерируем случайный порт и проверяем что он свободен
            while true; do
                new_ssh_port=$(( RANDOM % 16000 + 49000 ))
                if ! ss -tlnp | grep -q ":${new_ssh_port} "; then
                    break
                fi
            done
            info "Случайный порт: ${BOLD}${new_ssh_port}${RESET}"
            ;;
        *)
            new_ssh_port="$current_port"
            info "Порт оставляем: $current_port"
            ;;
    esac

    # ── Шаг 4: Применяем sshd_config ─────────────────────────
    hr
    echo -e "${BOLD}  Шаг 4: Настройка sshd_config${RESET}"
    hr

    # Бэкап — сохраняем метку времени для возможного отката
    local sshd_backup
    sshd_backup="${sshd_config}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$sshd_config" "$sshd_backup"
    ok "Бэкап sshd_config создан: $sshd_backup"

    # Применяем настройки
    local disable_root="yes"
    local disable_pass="yes"

    # Если нет ключа для нового пользователя — не отключаем пароль
    if [[ ! -f "$auth_keys" ]] || ! grep -q "ssh-" "$auth_keys" 2>/dev/null; then
        warn "Нет SSH-ключа — пароль оставляем включённым"
        disable_pass="no"
    fi

    # Меняем настройки
    sed -i "s/^#*Port .*/Port ${new_ssh_port}/" "$sshd_config"
    sed -i "s/^#*PermitRootLogin .*/PermitRootLogin ${disable_root}/" "$sshd_config"
    sed -i "s/^#*PasswordAuthentication .*/PasswordAuthentication ${disable_pass}/" "$sshd_config"
    sed -i "s/^#*PubkeyAuthentication .*/PubkeyAuthentication yes/" "$sshd_config"
    sed -i "s/^#*AuthorizedKeysFile .*/AuthorizedKeysFile .ssh\/authorized_keys/" "$sshd_config"
    sed -i "s/^#*X11Forwarding .*/X11Forwarding no/" "$sshd_config"
    sed -i "s/^#*MaxAuthTries .*/MaxAuthTries 3/" "$sshd_config"
    sed -i "s/^#*LoginGraceTime .*/LoginGraceTime 30/" "$sshd_config"
    sed -i "s/^#*PermitEmptyPasswords .*/PermitEmptyPasswords no/" "$sshd_config"

    # Добавляем если нет
    grep -q "^ClientAliveInterval" "$sshd_config" || echo "ClientAliveInterval 300" >> "$sshd_config"
    grep -q "^ClientAliveCountMax" "$sshd_config" || echo "ClientAliveCountMax 2"  >> "$sshd_config"

    # Проверяем конфиг
    if ! sshd -t 2>/dev/null; then
        err "Ошибка в sshd_config! Откатываю из $sshd_backup..."
        cp "$sshd_backup" "$sshd_config" 2>/dev/null || true
        return 1
    fi

    # ── Шаг 5: UFW + Fail2Ban ─────────────────────────────────
    hr
    echo -e "${BOLD}  Шаг 5: Firewall + Fail2Ban${RESET}"
    hr

    # Убеждаемся что UFW активен
    if ! ufw status | grep -q "Status: active"; then
        warn "UFW неактивен — включаю..."
        ufw --force enable >/dev/null 2>&1 || true
    fi
    # Открываем новый порт ПЕРЕД закрытием старого
    ufw allow "${new_ssh_port}/tcp" comment "SSH hardened" >/dev/null 2>&1 || true

    # Закрываем старый порт только если он изменился
    if [[ "$new_ssh_port" != "$current_port" ]]; then
        ufw delete allow "${current_port}/tcp" >/dev/null 2>&1 || true
        ufw delete allow ssh >/dev/null 2>&1 || true
        ok "Старый SSH порт ${current_port} закрыт в UFW"
    fi

    ok "Новый SSH порт ${new_ssh_port} открыт в UFW"

    # Fail2Ban
    apt-get install -y -q fail2ban

    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 3
backend  = systemd

[sshd]
enabled  = true
port     = ${new_ssh_port}
logpath  = %(sshd_log)s
maxretry = 3
bantime  = 86400
EOF

    systemctl enable fail2ban --quiet
    systemctl restart fail2ban
    ok "Fail2Ban настроен (3 попытки → бан на 24 часа)"

    # ── Перезапуск sshd ───────────────────────────────────────
    systemctl restart sshd
    ok "sshd перезапущен с новыми настройками"

    # Маркер
    mkdir -p "$CONFIG_DIR"
    cat > "$SSH_HARDENING_DONE" << EOF
SSH_PORT=${new_ssh_port}
SSH_USER=${target_user}
HARDENED_AT=$(date '+%Y-%m-%d %H:%M:%S')
EOF

    # ── Итог ─────────────────────────────────────────────────
    local server_ip
    server_ip=$(curl -s4 --max-time 5 https://ifconfig.me 2>/dev/null         || curl -s4 --max-time 5 https://api.ipify.org 2>/dev/null || echo "YOUR_IP")

    hr
    echo -e "${BOLD}${GREEN}  SSH Hardening завершён!${RESET}"
    hr
    echo -e "  ${BOLD}Новый SSH порт:${RESET}  ${CYAN}${new_ssh_port}${RESET}"
    echo -e "  ${BOLD}Пользователь:${RESET}   ${CYAN}${target_user}${RESET}"
    echo -e "  ${BOLD}Root вход:${RESET}      ${RED}запрещён${RESET}"
    echo -e "  ${BOLD}Пароль вход:${RESET}    $([ "$disable_pass" = "yes" ] && echo -e "${RED}запрещён${RESET}" || echo -e "${YELLOW}разрешён${RESET}")"
    echo -e "  ${BOLD}Fail2Ban:${RESET}       ${GREEN}активен${RESET}"
    echo
    echo -e "  ${BOLD}Подключение:${RESET}"
    echo -e "  ${CYAN}ssh -i ~/.ssh/id_naiveproxy -p ${new_ssh_port} ${target_user}@${server_ip}${RESET}"
    hr

    tg_send "🔒 <b>SSH Hardening выполнен</b>
🖥 Сервер: <code>$(hostname)</code>
🔑 Пользователь: <code>${target_user}</code>
🚪 SSH порт: <code>${new_ssh_port}</code>
🛡 Fail2Ban: включён
🕐 $(date '+%Y-%m-%d %H:%M:%S')"
}

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
💿 Диск: $(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')

🔐 <b>Сертификат:</b>
$(
cert_days=""
cert_info=$(echo | timeout 5 openssl s_client -connect "${DOMAIN:-localhost}:443" -servername "${DOMAIN:-localhost}" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "")
if [[ -n "$cert_info" ]]; then
    not_after=$(echo "$cert_info" | grep "notAfter" | cut -d= -f2)
    expire_ts=$(date -d "$not_after" +%s 2>/dev/null || echo 0)
    now_ts=$(date +%s)
    cert_days=$(( (expire_ts - now_ts) / 86400 ))
    echo "📅 Истекает: ${not_after}"
    echo "⏳ Осталось: ${cert_days} дней"
else
    echo "❓ Недоступен"
fi
)"
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
if [[ -f "$CONFIG_FILE" ]]; then
    _owner=$(stat -c '%U' "$CONFIG_FILE" 2>/dev/null || echo "unknown")
    [[ "$_owner" == "root" ]] && source "$CONFIG_FILE"
fi

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
    # Если запущен через bash <(curl), $0 будет /dev/fd/xx — используем фиксированный путь
    script_path=$(realpath "$0" 2>/dev/null || echo "")
    if [[ -z "$script_path" || "$script_path" == /dev/fd/* || "$script_path" == /proc/* ]]; then
        script_path="/usr/local/bin/naiveproxy.sh"
        # Копируем себя в постоянное место если ещё не там
        [[ -f "$script_path" ]] || cp "$0" "$script_path" 2>/dev/null || true
        [[ -f "$script_path" ]] && chmod +x "$script_path"
    fi

    # Очищаем старые naive-cron записи, добавляем новые
    ( crontab -l 2>/dev/null | grep -v "naiveproxy\|monitor\.sh" || true
      echo "*/5 * * * * /bin/bash $MONITOR_SCRIPT"
      echo "0 3 * * 0 /bin/bash ${script_path} update >> ${LOG_DIR}/autoupdate.log 2>&1"
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
        printf 'export PATH="/usr/local/go/bin:$PATH"\n' > /etc/profile.d/go.sh
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
    command -v ufw &>/dev/null || { warn "UFW не найден, пропускаю"; return; }
    info "Настраиваю UFW..."
    # Включаем UFW если не активен
    if ! ufw status | grep -q "Status: active"; then
        ufw --force enable >/dev/null 2>&1 || true
        ok "UFW включён"
    fi
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
        check_cert "${DOMAIN:-}"
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

    # ── Шаг 0: Обновление системы ────────────────────────────
    if [[ ! -f "$SYSUPDATE_DONE" ]]; then
        echo -ne "${YELLOW}Обновить систему перед установкой? [Y/n]: ${RESET}"
        read -r ans
        [[ "${ans,,}" != "n" ]] && cmd_sysupdate
    else
        info "Система уже обновлялась: $(cat "$SYSUPDATE_DONE")"
    fi

    # ── Шаг 1: SSH Hardening ─────────────────────────────────
    if [[ ! -f "$SSH_HARDENING_DONE" ]]; then
        echo -ne "${YELLOW}Выполнить SSH Hardening? [Y/n]: ${RESET}"
        read -r ans
        [[ "${ans,,}" != "n" ]] && cmd_ssh_hardening
    else
        info "SSH уже настроен: $(grep SSH_PORT "$SSH_HARDENING_DONE" | cut -d= -f2)"
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


# ─── ПРОВЕРКА СЕРТИФИКАТА ─────────────────────────────────────
check_cert() {
    local domain="${1:-${DOMAIN:-}}"
    [[ -z "$domain" ]] && return

    echo
    echo -e "  ${BOLD}TLS Сертификат:${RESET}"

    local cert_info
    cert_info=$(echo | timeout 5 openssl s_client -connect "${domain}:443"         -servername "$domain" 2>/dev/null | openssl x509 -noout         -dates -issuer -subject 2>/dev/null || echo "")

    if [[ -z "$cert_info" ]]; then
        warn "Не удалось получить данные сертификата"
        return
    fi

    local not_after issuer
    not_after=$(echo "$cert_info" | grep "notAfter" | cut -d= -f2)
    issuer=$(echo "$cert_info" | grep "issuer" | grep -oP "O=\K[^,]+" || echo "н/д")

    # Считаем дней до истечения
    local expire_ts now_ts days_left
    expire_ts=$(date -d "$not_after" +%s 2>/dev/null || echo 0)
    now_ts=$(date +%s)
    days_left=$(( (expire_ts - now_ts) / 86400 ))

    # Цвет в зависимости от срока
    local days_color
    if [[ $days_left -gt 30 ]]; then
        days_color="${GREEN}"
    elif [[ $days_left -gt 7 ]]; then
        days_color="${YELLOW}"
    else
        days_color="${RED}"
    fi

    echo -e "  Домен:     ${CYAN}${domain}${RESET}"
    echo -e "  Истекает:  ${not_after}"
    echo -e "  Осталось:  ${days_color}${days_left} дней${RESET}"
    echo -e "  Выдан:     ${issuer}"

    if [[ $days_left -le 7 ]]; then
        err "СЕРТИФИКАТ ИСТЕКАЕТ МЕНЕЕ ЧЕМ ЧЕРЕЗ 7 ДНЕЙ!"
        tg_send "⚠️ <b>Сертификат истекает!</b>
🌐 Домен: <code>${domain}</code>
📅 Осталось: <b>${days_left} дней</b>
🕐 $(date '+%Y-%m-%d %H:%M:%S')
🔧 Caddy обновит автоматически — проверь что он запущен!"
    elif [[ $days_left -le 30 ]]; then
        warn "Сертификат истекает через ${days_left} дней — Caddy обновит автоматически"
    else
        ok "Сертификат действителен ещё ${days_left} дней"
    fi
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
    check_cert "${DOMAIN:-}"
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
    local ssh_str="${YELLOW}не настроен${RESET}"
    [[ -f "$SSH_HARDENING_DONE" ]] && ssh_str="${GREEN}$(grep SSH_PORT "$SSH_HARDENING_DONE" 2>/dev/null | cut -d= -f2)${RESET}"
    echo -e "   Telegram: ${tg_str}  |  Юзеров: $(get_users | wc -l)  |  SSH порт: ${ssh_str}"
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
    echo -e "   ──────────────────────────"
    echo -e "   ${BOLD}11)${RESET} 🔒 SSH Hardening"
    echo -e "   ${BOLD}12)${RESET} 🔄 Обновить систему"
    echo -e "   ${BOLD}0)${RESET}  Выход"
    hr
    echo -ne "${CYAN}Выбор [0-12]: ${RESET}"
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
            tg-stats)      tg_send_stats; ok "Отправлено" ;;
            ssh-hardening) cmd_ssh_hardening ;;
            sysupdate)     cmd_sysupdate ;;
            cert)          load_config; check_cert "${DOMAIN:-}" ;;
            *) err "Неизвестная команда: $1"
               echo "Доступные: install status config restart update remove logs monitor users tg-stats ssh-hardening sysupdate cert"
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
            11) cmd_ssh_hardening ;;
            12) cmd_sysupdate ;;
            0)  echo -e "${GREEN}Пока!${RESET}"; exit 0 ;;
            *)  warn "Неверный выбор" ;;
        esac
        echo
        echo -ne "${YELLOW}Нажми Enter чтобы вернуться в меню...${RESET}"
        read -r
    done
}

main "$@"
