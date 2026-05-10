#!/bin/bash
# ============================================================
#   NaiveProxy Manager v4.2.1 — by ivanstudiya-cpu
#   Стек: Caddy 2 + klzgrad/forwardproxy@naive
#   ОС: Ubuntu 20.04 / 22.04 / 24.04
#   GitHub: https://github.com/ivanstudiya-cpu/naiveproxy
# ============================================================

set -euo pipefail

VERSION="4.2.2"
LANG_UI="${NAIVEPROXY_LANG:-ru}"  # ru или en — export NAIVEPROXY_LANG=en
GITHUB_RAW="https://raw.githubusercontent.com/ivanstudiya-cpu/naiveproxy/main/naiveproxy.sh"
GITHUB_API="https://api.github.com/repos/ivanstudiya-cpu/naiveproxy/releases/latest"
SCRIPT_PATH="/usr/local/bin/naiveproxy.sh"

# ─── Цвета ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
GOLD='\033[0;33m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}[✓]${RESET} $*"; }
err()  { echo -e "${RED}[✗]${RESET} $*"; }
info() { echo -e "${CYAN}[i]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }
hr()   { echo -e "${CYAN}──────────────────────────────────────────${RESET}"; }

# ─── Баннер при первом запуске ────────────────────────────────
show_banner() {
    echo -e "${BOLD}${CYAN}"
    echo '  ███╗   ██╗ █████╗ ██╗██╗   ██╗███████╗'
    echo '  ████╗  ██║██╔══██╗██║██║   ██║██╔════╝'
    echo '  ██╔██╗ ██║███████║██║██║   ██║█████╗  '
    echo '  ██║╚██╗██║██╔══██║██║╚██╗ ██╔╝██╔══╝  '
    echo '  ██║ ╚████║██║  ██║██║ ╚████╔╝ ███████╗'
    echo '  ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝'
    echo -e "${RESET}"
    echo -e "  ${BOLD}${GOLD}██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗${RESET}"
    echo -e "  ${BOLD}${GOLD}██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝${RESET}"
    echo -e "  ${BOLD}${GOLD}██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝ ${RESET}"
    echo -e "  ${BOLD}${GOLD}██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝  ${RESET}"
    echo -e "  ${BOLD}${GOLD}██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║   ${RESET}"
    echo -e "  ${BOLD}${GOLD}╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ${RESET}"
    echo
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${BOLD}  NaiveProxy Manager${RESET} ${DIM}v${VERSION}${RESET}  ${DIM}·${RESET}  ${CYAN}by Иван Юрьевич${RESET}"
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
    echo -e "  ${YELLOW}🔔 Обновления выходят раз в месяц${RESET}"
    echo -e "  ${CYAN}📱 Telegram:${RESET} https://t.me/+XVSkY6blCTY0ZDU6"
    echo -e "  ${CYAN}🌐 Сайт:${RESET}     https://ivan-it.net"
    echo -e "  ${CYAN}💻 GitHub:${RESET}   github.com/ivanstudiya-cpu/naiveproxy"
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
}

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

        # Авто-сохранение ключа в /etc/naiveproxy/
        mkdir -p "$CONFIG_DIR"
        cp "${ssh_dir}/id_ed25519_server"     "${CONFIG_DIR}/ssh_private_key"
        cp "${ssh_dir}/id_ed25519_server.pub" "${CONFIG_DIR}/ssh_public_key"
        chmod 600 "${CONFIG_DIR}/ssh_private_key"
        ok "SSH ключ авто-сохранён: ${CONFIG_DIR}/ssh_private_key"

        echo
        echo -e "${RED}╔══════════════════════════════════════════════════════╗${RESET}"
        echo -e "${RED}║  ПРИВАТНЫЙ КЛЮЧ — СКОПИРУЙ И СОХРАНИ ПРЯМО СЕЙЧАС  ║${RESET}"
        echo -e "${RED}╚══════════════════════════════════════════════════════╝${RESET}"
        cat "${ssh_dir}/id_ed25519_server"
        echo -e "${RED}══════════════════════════════════════════════════════${RESET}"
        echo

        # Команда для скачивания ключа с сервера
        local server_ip_tmp
        server_ip_tmp=$(curl -s4 --max-time 5 https://ifconfig.me 2>/dev/null || echo YOUR_IP)
        echo -e "  ${BOLD}Скачать ключ на свой компьютер:${RESET}"
        echo -e "  ${CYAN}# Linux/macOS:${RESET}"
        echo -e "  scp root@${server_ip_tmp}:${CONFIG_DIR}/ssh_private_key ~/.ssh/id_naiveproxy"
        echo -e "  chmod 600 ~/.ssh/id_naiveproxy"
        echo
        echo -e "  ${CYAN}# Windows PowerShell:${RESET}"
        echo -e "  scp root@${server_ip_tmp}:${CONFIG_DIR}/ssh_private_key \$HOME\.ssh\id_naiveproxy"
        echo
        warn "Подключение после hardening:"
        echo -e "  ${CYAN}ssh -i ~/.ssh/id_naiveproxy -p [НОВЫЙ_ПОРТ] ${target_user}@${server_ip_tmp}${RESET}"
        echo
        echo -ne "${YELLOW}Ты сохранил/скачал ключ? [yes]: ${RESET}"
        read -r confirm
        if [[ "${confirm,,}" != "yes" && "${confirm,,}" != "y" ]]; then
            warn "Ключ сохранён на сервере: ${CONFIG_DIR}/ssh_private_key"
            warn "Скачай его позже через scp!"
            echo -ne "${YELLOW}Продолжить? [y/N]: ${RESET}"
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
    # Проверяем что строка Port вообще есть
    if grep -qE "^#?Port " "$sshd_config"; then
        sed -i "s/^#*Port .*/Port ${new_ssh_port}/" "$sshd_config"
    else
        echo "Port ${new_ssh_port}" >> "$sshd_config"
    fi
    # На Ubuntu 22.04+ конфиг может быть в /etc/ssh/sshd_config.d/*.conf
    for cfg in /etc/ssh/sshd_config.d/*.conf; do
        [[ ! -f "$cfg" ]] && continue
        if grep -qE "^#?Port " "$cfg"; then
            sed -i "s/^#*Port .*/Port ${new_ssh_port}/" "$cfg"
        fi
    done
    # Ubuntu 22.04+ использует ssh.socket — нужно отключить
    if systemctl is-enabled ssh.socket &>/dev/null; then
        info "Отключаю ssh.socket (Ubuntu 22.04+ override)..."
        systemctl disable ssh.socket --quiet 2>/dev/null || true
        systemctl stop ssh.socket 2>/dev/null || true
    fi
    # PermitRootLogin
    if grep -qE "^#?PermitRootLogin " "$sshd_config"; then
        sed -i "s/^#*PermitRootLogin .*/PermitRootLogin ${disable_root}/" "$sshd_config"
    else
        echo "PermitRootLogin ${disable_root}" >> "$sshd_config"
    fi
    # PasswordAuthentication
    if grep -qE "^#?PasswordAuthentication " "$sshd_config"; then
        sed -i "s/^#*PasswordAuthentication .*/PasswordAuthentication ${disable_pass}/" "$sshd_config"
    else
        echo "PasswordAuthentication ${disable_pass}" >> "$sshd_config"
    fi
    # Также в conf.d файлах (Ubuntu 22.04+)
    for cfg in /etc/ssh/sshd_config.d/*.conf; do
        [[ ! -f "$cfg" ]] && continue
        sed -i "s/^#*PermitRootLogin .*/PermitRootLogin ${disable_root}/" "$cfg" 2>/dev/null || true
        sed -i "s/^#*PasswordAuthentication .*/PasswordAuthentication ${disable_pass}/" "$cfg" 2>/dev/null || true
    done
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
    apt-get update -qq 2>/dev/null || true
    apt-get install -y -q fail2ban

    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
# Глобальные настройки
bantime   = 86400    # Бан 24 часа
findtime  = 600      # Окно поиска 10 минут
maxretry  = 3        # Максимум попыток
backend   = systemd
banaction = iptables-multiport

[sshd]
enabled   = true
port      = ${new_ssh_port}
logpath   = %(sshd_log)s
maxretry  = 3
bantime   = 604800   # Бан 7 дней за брутфорс SSH

[sshd-ddos]
enabled   = true
port      = ${new_ssh_port}
logpath   = %(sshd_log)s
maxretry  = 10
findtime  = 60       # 10 попыток за 1 минуту = DDoS бан
bantime   = 604800

[recidive]
enabled   = true
logpath   = /var/log/fail2ban.log
banaction = ufw
bantime   = 2592000  # Рецидивисты — бан на 30 дней
findtime  = 86400
maxretry  = 3
EOF

    # Настройка action для UFW
    cat > /etc/fail2ban/action.d/ufw.conf << 'UEOF'
[Definition]
actionstart =
actionstop  =
actioncheck =
actionban   = ufw insert 1 deny from <ip> to any
actionunban = ufw delete deny from <ip> to any
UEOF

    systemctl enable fail2ban --quiet
    systemctl restart fail2ban
    ok "Fail2Ban настроен:"
    ok "  SSH брутфорс: 3 попытки → бан 7 дней"
    ok "  SSH DDoS: 10 попыток за 1 мин → бан 7 дней"
    ok "  Рецидивисты: → бан 30 дней"

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


# ─── МУЛЬТИЯЗЫЧНОСТЬ ──────────────────────────────────────────
# Использование: t "Текст на русском" "English text"
t() {
    if [[ "${LANG_UI}" == "en" ]]; then
        echo "$2"
    else
        echo "$1"
    fi
}

# Установить язык: export NAIVEPROXY_LANG=en
# Set language:   export NAIVEPROXY_LANG=en

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
        # Проверяем владельца перед source
        local _cfg_owner
        _cfg_owner=$(stat -c '%U' "$CONFIG_FILE" 2>/dev/null || echo "unknown")
        if [[ "$_cfg_owner" == "root" ]]; then
            # shellcheck source=/dev/null
            source "$CONFIG_FILE"
        else
            warn "CONFIG_FILE принадлежит не root — пропускаю source"
        fi
    fi
}

save_config() {
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" <<EOF
DOMAIN="${DOMAIN:-}"
DOMAINS="${DOMAINS:-${DOMAIN:-}}"
EMAIL="${EMAIL:-}"
TG_TOKEN="${TG_TOKEN:-}"
TG_CHAT_ID="${TG_CHAT_ID:-}"
TG_ADMINS="${TG_ADMINS:-}"  # Доп. администраторы через запятую: id1,id2,id3
TG_ADMINS="${TG_ADMINS:-}"
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
    # Используем --data-urlencode для безопасной передачи спецсимволов
    curl -s --max-time 10 --retry 2 --retry-delay 3 \
        -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=${TG_CHAT_ID}" \
        --data-urlencode "parse_mode=HTML" \
        --data-urlencode "text=${message}" \
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
        -H "Content-Type: application/json" \
        -d "{"chat_id":"${TG_CHAT_ID}","parse_mode":"HTML","text":"${msg}"}" \
        >/dev/null 2>&1 || true
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
    info "Занимает 5-15 минут, не прерывай..."

    export PATH="/usr/local/go/bin:$PATH"
    export GOPATH="/root/go"
    export GOCACHE="/root/.cache/go-build"

    # Ставим git если нет
    command -v git &>/dev/null || apt-get install -y -q git

    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

    # Клонируем naive ветку напрямую — единственный надёжный способ
    local fp_dir="/tmp/klzgrad-forwardproxy"
    [[ -n "${fp_dir}" ]] && rm -rf "${fp_dir}"
    info "Клонирую klzgrad/forwardproxy@naive..."
    if ! git clone -b naive --depth 1         https://github.com/klzgrad/forwardproxy.git "$fp_dir" 2>/dev/null; then
        err "Не удалось клонировать forwardproxy. Проверь интернет."
        exit 1
    fi

    # Читаем точную версию Caddy из go.mod forwardproxy
    local caddy_ver
    caddy_ver=$(grep 'github.com/caddyserver/caddy/v2 ' "$fp_dir/go.mod"         | awk '{print $2}' | head -1)
    info "Forwardproxy требует Caddy: $caddy_ver"

    # Собираем именно эту версию Caddy с локальным forwardproxy
    "$GOPATH/bin/xcaddy" build "${caddy_ver}" \
        --with github.com/caddyserver/forwardproxy="$fp_dir" \
        --output "$CADDY_BIN"

    chmod +x "$CADDY_BIN"

    # Проверяем наличие naive padding в бинарнике
    if command -v strings &>/dev/null; then
        local _pc
        _pc=$(strings "$CADDY_BIN" 2>/dev/null | grep -cE "^(Padding|SetPadding|WithPadding)$" || true)
        _pc="${_pc//[^0-9]/}"; _pc="${_pc:-0}"
        if [[ "${_pc}" -ge 2 ]]; then
            ok "Naive padding модуль подтверждён ✓"
        else
            warn "Padding не найден — возможна проблема совместимости"
        fi
    fi

    [[ -n "${fp_dir}" ]] && rm -rf "${fp_dir}"
    ok "Caddy собран: $("$CADDY_BIN" version 2>/dev/null | head -1)"
}


# ── Мультидомен: генерация Caddyfile ─────────────────────────
write_caddyfile_multi() {
    mkdir -p "$CADDY_DIR" "$WEBROOT" "$LOG_DIR"

    install_camouflage_page

    # Собираем auth блоки
    local auth_blocks=""
    while IFS=: read -r u p; do
        [[ -z "$u" ]] && continue
        auth_blocks+="        basic_auth ${u} ${p}"$'\n'
    done < <(get_users)

    # Глобальный блок
    cat > "$CADDYFILE" <<EOF
{
  order forward_proxy before file_server
  servers :443 {
      protocols h1 h2 h3
  }
  log {
    output file ${LOG_DIR}/access.log {
      roll_size 50mb
      roll_keep 3
    }
  }
}

EOF

    # Блок для каждого домена
    local domains_list
    IFS=',' read -ra domains_list <<< "${DOMAINS:-${DOMAIN:-}}"

    for dom in "${domains_list[@]}"; do
        dom="${dom// /}"  # убираем пробелы
        [[ -z "$dom" ]] && continue
        cat >> "$CADDYFILE" <<EOF
${dom}:443 {
    tls ${EMAIL}

  forward_proxy {
${auth_blocks}    hide_ip
    hide_via
    probe_resistance
  }

  file_server {
    root ${WEBROOT}
  }

    log {
        output file ${LOG_DIR}/naive_${dom//./_}.log {
            roll_size 20mb
            roll_keep 5
        }
    }
}

EOF
    done

    chmod 600 "$CADDYFILE"
    local dom_count
    dom_count=$(echo "${DOMAINS:-${DOMAIN:-}}" | tr ',' '\n' | grep -c '[a-z]' || echo 1)
    ok "Caddyfile обновлён (доменов: ${dom_count}, пользователей: $(get_users | wc -l))"
}


# ─── КАМУФЛЯЖНАЯ СТРАНИЦА ────────────────────────────────────────
install_camouflage_page() {
    mkdir -p "$WEBROOT"

    cat > "$WEBROOT/index.html" << 'CAMOUFLAGE_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="description" content="DevStack — Technical notes on Linux, networking, security and open source infrastructure.">
<title>DevStack — Linux & Infrastructure Notes</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;700&family=Syne:wght@400;600;800&display=swap" rel="stylesheet">
<style>
:root{--bg:#080B0F;--bg2:#0D1117;--bg3:#161B22;--border:#21262D;--gold:#D4A017;--gold2:#F0C040;--text:#E6EDF3;--text-dim:#7D8590;--text-muted:#484F58;--green:#3FB950;--blue:#58A6FF;--red:#F85149;--tag-bg:#1F2937}
*{margin:0;padding:0;box-sizing:border-box}html{scroll-behavior:smooth}
body{background:var(--bg);color:var(--text);font-family:'Syne',sans-serif;font-size:16px;line-height:1.6;min-height:100vh}
body::before{content:'';position:fixed;inset:0;background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,0,0,.03) 2px,rgba(0,0,0,.03) 4px);pointer-events:none;z-index:9999}
code,pre,.mono{font-family:'JetBrains Mono',monospace}
a{color:var(--blue);text-decoration:none}a:hover{color:var(--gold2)}
header{border-bottom:1px solid var(--border);background:var(--bg2);position:sticky;top:0;z-index:100;backdrop-filter:blur(8px)}
.header-inner{max-width:1100px;margin:0 auto;padding:0 24px;height:60px;display:flex;align-items:center;justify-content:space-between}
.logo{display:flex;align-items:center;gap:10px;text-decoration:none}
.logo-icon{width:32px;height:32px;background:var(--gold);border-radius:6px;display:flex;align-items:center;justify-content:center;font-family:'JetBrains Mono',monospace;font-weight:700;font-size:14px;color:#000}
.logo-text{font-size:18px;font-weight:800;color:var(--text);letter-spacing:-.5px}
.logo-text span{color:var(--gold)}
nav{display:flex;gap:28px;align-items:center}
nav a{font-size:14px;font-weight:600;color:var(--text-dim);letter-spacing:.3px;transition:color .2s}
nav a:hover{color:var(--text)}
.nav-rss{display:flex;align-items:center;gap:6px;padding:6px 14px;border:1px solid var(--border);border-radius:6px;font-size:13px;color:var(--text-dim)!important;transition:border-color .2s,color .2s!important}
.nav-rss:hover{border-color:var(--gold)!important;color:var(--gold)!important}
.hero{border-bottom:1px solid var(--border);padding:64px 24px 48px;position:relative;overflow:hidden}
.hero::after{content:'';position:absolute;top:-80px;right:-80px;width:400px;height:400px;background:radial-gradient(circle,rgba(212,160,23,.06) 0%,transparent 70%);pointer-events:none}
.hero-inner{max-width:1100px;margin:0 auto}
.hero-eyebrow{display:inline-flex;align-items:center;gap:8px;font-family:'JetBrains Mono',monospace;font-size:12px;color:var(--gold);margin-bottom:20px;letter-spacing:1px}
.hero-eyebrow::before{content:'';display:inline-block;width:24px;height:1px;background:var(--gold)}
.hero h1{font-size:clamp(32px,5vw,52px);font-weight:800;line-height:1.1;letter-spacing:-1.5px;max-width:700px;margin-bottom:20px}
.hero h1 em{font-style:normal;color:var(--gold)}
.hero p{font-size:17px;color:var(--text-dim);max-width:540px;line-height:1.7}
.main{max-width:1100px;margin:0 auto;padding:48px 24px;display:grid;grid-template-columns:1fr 300px;gap:48px}
.featured{border:1px solid var(--border);border-radius:12px;overflow:hidden;margin-bottom:32px;background:var(--bg2);transition:border-color .2s}
.featured:hover{border-color:var(--gold)}
.featured-img{height:220px;background:linear-gradient(135deg,rgba(212,160,23,.15) 0%,transparent 60%),linear-gradient(225deg,rgba(88,166,255,.08) 0%,transparent 50%),var(--bg3);display:flex;align-items:center;justify-content:center;font-size:72px;position:relative;overflow:hidden}
.featured-img::before{content:'';position:absolute;inset:0;background:repeating-linear-gradient(45deg,transparent,transparent 20px,rgba(212,160,23,.02) 20px,rgba(212,160,23,.02) 40px)}
.featured-badge{position:absolute;top:16px;left:16px;background:var(--gold);color:#000;font-size:11px;font-weight:700;padding:4px 10px;border-radius:4px;letter-spacing:1px;font-family:'JetBrains Mono',monospace}
.featured-body{padding:28px}
.post-meta{display:flex;align-items:center;gap:12px;margin-bottom:12px;flex-wrap:wrap}
.tag{background:var(--tag-bg);color:var(--text-dim);font-size:11px;font-family:'JetBrains Mono',monospace;padding:3px 8px;border-radius:4px;border:1px solid var(--border)}
.tag.linux{color:var(--green);border-color:#3fb95040}
.tag.security{color:var(--red);border-color:#f8514940}
.tag.networking{color:var(--blue);border-color:#58a6ff40}
.tag.caddy{color:var(--gold);border-color:#d4a01740}
.post-date{font-size:12px;font-family:'JetBrains Mono',monospace;color:var(--text-muted);margin-left:auto}
.featured-body h2{font-size:24px;font-weight:800;letter-spacing:-.5px;margin-bottom:10px;line-height:1.25}
.featured-body h2 a{color:var(--text)}
.featured-body h2 a:hover{color:var(--gold)}
.featured-body p{color:var(--text-dim);font-size:15px;line-height:1.7;margin-bottom:20px}
.read-more{display:inline-flex;align-items:center;gap:8px;font-size:13px;font-weight:600;color:var(--gold);font-family:'JetBrains Mono',monospace;transition:all .2s}
.read-more:hover{color:var(--gold2);gap:12px}
.posts-label{font-size:11px;font-family:'JetBrains Mono',monospace;color:var(--text-muted);letter-spacing:2px;margin-bottom:16px;display:flex;align-items:center;gap:12px}
.posts-label::after{content:'';flex:1;height:1px;background:var(--border)}
.post-card{border:1px solid var(--border);border-radius:10px;padding:20px 22px;margin-bottom:12px;background:var(--bg2);display:grid;grid-template-columns:1fr auto;gap:12px;align-items:start;transition:border-color .2s,background .2s;cursor:pointer}
.post-card:hover{background:var(--bg3)}
.post-card h3{font-size:16px;font-weight:600;letter-spacing:-.3px;margin-bottom:6px;line-height:1.3}
.post-card h3 a{color:var(--text)}
.post-card h3 a:hover{color:var(--gold)}
.post-card p{font-size:13px;color:var(--text-dim);line-height:1.55}
.post-card-right{text-align:right;white-space:nowrap}
.read-time{font-size:11px;font-family:'JetBrains Mono',monospace;color:var(--text-muted);display:block;margin-top:8px}
.sidebar{display:flex;flex-direction:column;gap:24px}
.widget{border:1px solid var(--border);border-radius:10px;background:var(--bg2);overflow:hidden}
.widget-header{padding:14px 18px;border-bottom:1px solid var(--border);font-size:11px;font-family:'JetBrains Mono',monospace;color:var(--text-muted);letter-spacing:2px;display:flex;align-items:center;gap:8px}
.widget-header::before{content:'';width:6px;height:6px;background:var(--gold);border-radius:50%}
.widget-body{padding:18px}
.about-avatar{width:56px;height:56px;border-radius:50%;background:linear-gradient(135deg,var(--gold) 0%,#8B5E00 100%);display:flex;align-items:center;justify-content:center;font-size:22px;margin-bottom:14px;border:2px solid var(--border)}
.about-name{font-size:15px;font-weight:700;margin-bottom:4px}
.about-bio{font-size:13px;color:var(--text-dim);line-height:1.6;margin-bottom:14px}
.about-links{display:flex;gap:10px;flex-wrap:wrap}
.about-link{display:inline-flex;align-items:center;gap:5px;font-size:12px;font-family:'JetBrains Mono',monospace;color:var(--text-dim);border:1px solid var(--border);padding:5px 10px;border-radius:6px;transition:border-color .2s,color .2s}
.about-link:hover{border-color:var(--gold);color:var(--gold)}
.tags-cloud{display:flex;flex-wrap:wrap;gap:8px}
.tag-link{font-size:12px;font-family:'JetBrains Mono',monospace;padding:5px 10px;border-radius:6px;border:1px solid var(--border);color:var(--text-dim);transition:all .2s}
.tag-link:hover{border-color:var(--gold);color:var(--gold);background:rgba(212,160,23,.05)}
.terminal{background:var(--bg);border-radius:8px;overflow:hidden;font-family:'JetBrains Mono',monospace;font-size:12px}
.terminal-bar{background:var(--bg3);padding:8px 12px;display:flex;align-items:center;gap:6px;border-bottom:1px solid var(--border)}
.terminal-dot{width:10px;height:10px;border-radius:50%}
.terminal-body{padding:14px;color:var(--text-dim);line-height:1.9}
.terminal-body .prompt{color:var(--green)}
.terminal-body .cmd{color:var(--text)}
.terminal-body .out{color:var(--text-muted)}
.terminal-body .hl{color:var(--gold)}
.stats-bar{border-top:1px solid var(--border);border-bottom:1px solid var(--border);background:var(--bg2);padding:16px 24px}
.stats-inner{max-width:1100px;margin:0 auto;display:flex;gap:40px;flex-wrap:wrap}
.stat{display:flex;align-items:center;gap:10px}
.stat-num{font-size:22px;font-weight:800;color:var(--gold);letter-spacing:-1px;font-family:'JetBrains Mono',monospace}
.stat-label{font-size:12px;color:var(--text-muted);line-height:1.3}
footer{border-top:1px solid var(--border);padding:32px 24px;background:var(--bg2)}
.footer-inner{max-width:1100px;margin:0 auto;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:16px}
.footer-left{font-size:13px;color:var(--text-muted);font-family:'JetBrains Mono',monospace}
.footer-left span{color:var(--gold)}
.footer-links{display:flex;gap:20px}
.footer-links a{font-size:13px;color:var(--text-muted);transition:color .2s}
.footer-links a:hover{color:var(--gold)}
@keyframes fadeUp{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}
@keyframes blink{0%,100%{opacity:1}50%{opacity:0}}
.cursor{display:inline-block;width:8px;height:14px;background:var(--green);vertical-align:middle;animation:blink 1s step-end infinite;border-radius:1px}
.hero{animation:fadeUp .5s ease both}
.featured{animation:fadeUp .5s .1s ease both}
@media(max-width:768px){.main{grid-template-columns:1fr}.sidebar{display:none}nav a:not(.nav-rss){display:none}}
</style>
</head>
<body>
<header>
  <div class="header-inner">
    <a href="/" class="logo"><div class="logo-icon">&gt;_</div><span class="logo-text">Dev<span>Stack</span></span></a>
    <nav>
      <a href="#">Linux</a><a href="#">Security</a><a href="#">Networking</a><a href="#">Tools</a>
      <a href="#" class="nav-rss">RSS</a>
    </nav>
  </div>
</header>
<section class="hero">
  <div class="hero-inner">
    <div class="hero-eyebrow">TECHNICAL NOTES</div>
    <h1>Linux, Networking<br>&amp; <em>Infrastructure</em></h1>
    <p>Practical notes on server administration, open source tooling, and building reliable systems. No fluff — just working code and real-world configs.</p>
  </div>
</section>
<div class="stats-bar">
  <div class="stats-inner">
    <div class="stat"><span class="stat-num">47</span><span class="stat-label">articles<br>published</span></div>
    <div class="stat"><span class="stat-num">12k</span><span class="stat-label">monthly<br>readers</span></div>
    <div class="stat"><span class="stat-num">3y</span><span class="stat-label">writing<br>about Linux</span></div>
    <div class="stat"><span class="stat-num mono">100%</span><span class="stat-label">self-hosted<br>infrastructure</span></div>
  </div>
</div>
<div class="main">
  <main>
    <article class="featured">
      <div class="featured-img">🔐<span class="featured-badge">FEATURED</span></div>
      <div class="featured-body">
        <div class="post-meta"><span class="tag security">security</span><span class="tag linux">linux</span><span class="tag networking">networking</span><span class="post-date mono">Apr 21, 2026</span></div>
        <h2><a href="#">Hardening a Fresh Ubuntu VPS in 2026: The Complete Checklist</a></h2>
        <p>Every time I spin up a new VPS it gets thousands of SSH brute-force attempts within hours. Here's the exact sequence I run — from changing the SSH port and setting up Fail2Ban to configuring unattended security updates and locking down UFW.</p>
        <a href="#" class="read-more">Read article →</a>
      </div>
    </article>
    <div class="posts-label">RECENT POSTS</div>
    <article class="post-card">
      <div><div class="post-meta"><span class="tag caddy">caddy</span><span class="tag networking">networking</span></div><h3><a href="#">Caddy 2 as a Reverse Proxy: Automatic TLS, HTTP/3 and Zero Config</a></h3><p>Forget manually managing Let's Encrypt certificates. Caddy does it all — including HTTP/3 via QUIC — with a ten-line config.</p></div>
      <div class="post-card-right"><span class="post-date mono">Apr 14</span><span class="read-time">7 min</span></div>
    </article>
    <article class="post-card">
      <div><div class="post-meta"><span class="tag linux">linux</span><span class="tag security">security</span></div><h3><a href="#">ED25519 vs RSA: Why You Should Migrate Your SSH Keys Today</a></h3><p>RSA-4096 is not broken, but ED25519 is smaller, faster, and safer against side-channel attacks. Here's how to migrate without locking yourself out.</p></div>
      <div class="post-card-right"><span class="post-date mono">Apr 08</span><span class="read-time">5 min</span></div>
    </article>
    <article class="post-card">
      <div><div class="post-meta"><span class="tag linux">linux</span></div><h3><a href="#">Systemd Timers vs Cron: A Practical Comparison for 2026</a></h3><p>Cron is simple and it works. Systemd timers are more powerful. I compared both for a production automation task — here's what I found.</p></div>
      <div class="post-card-right"><span class="post-date mono">Mar 30</span><span class="read-time">6 min</span></div>
    </article>
    <article class="post-card">
      <div><div class="post-meta"><span class="tag networking">networking</span><span class="tag security">security</span></div><h3><a href="#">UFW Deep Dive: Rules, Logging and Common Mistakes</a></h3><p>UFW is friendly but hides complexity. I cover rule ordering, default policies, logging levels, and the three mistakes that get people locked out of their own servers.</p></div>
      <div class="post-card-right"><span class="post-date mono">Mar 22</span><span class="read-time">9 min</span></div>
    </article>
    <article class="post-card">
      <div><div class="post-meta"><span class="tag linux">linux</span><span class="tag caddy">caddy</span></div><h3><a href="#">Building a Minimal Self-Hosted Stack: No Docker, No Kubernetes</a></h3><p>Not every project needs containers. A plain Ubuntu server with Caddy, systemd and a deploy script can run production workloads reliably with far less overhead.</p></div>
      <div class="post-card-right"><span class="post-date mono">Mar 15</span><span class="read-time">11 min</span></div>
    </article>
  </main>
  <aside class="sidebar">
    <div class="widget">
      <div class="widget-header">ABOUT</div>
      <div class="widget-body">
        <div class="about-avatar">👨‍💻</div>
        <div class="about-name">Ivan Yu.</div>
        <p class="about-bio">Sysadmin and open source enthusiast. Writing about Linux, networking and the infrastructure behind the web since 2021.</p>
        <div class="about-links"><a href="#" class="about-link">⌂ GitHub</a><a href="#" class="about-link">✉ Contact</a></div>
      </div>
    </div>
    <div class="widget">
      <div class="widget-header">UPTIME</div>
      <div class="widget-body" style="padding:0">
        <div class="terminal">
          <div class="terminal-bar"><div class="terminal-dot" style="background:#f85149"></div><div class="terminal-dot" style="background:#d4a017"></div><div class="terminal-dot" style="background:#3fb950"></div></div>
          <div class="terminal-body">
            <div><span class="prompt">$</span> <span class="cmd">uptime -p</span></div>
            <div class="out">up <span class="hl">47 days</span>, 3 hours</div>
            <div style="margin-top:8px"><span class="prompt">$</span> <span class="cmd">systemctl is-active caddy</span></div>
            <div class="out" style="color:#3fb950">active</div>
            <div style="margin-top:8px"><span class="prompt">$</span> <span class="cursor"></span></div>
          </div>
        </div>
      </div>
    </div>
    <div class="widget">
      <div class="widget-header">TOPICS</div>
      <div class="widget-body">
        <div class="tags-cloud">
          <a href="#" class="tag-link">linux</a><a href="#" class="tag-link">security</a><a href="#" class="tag-link">caddy</a><a href="#" class="tag-link">ssh</a><a href="#" class="tag-link">ufw</a><a href="#" class="tag-link">fail2ban</a><a href="#" class="tag-link">networking</a><a href="#" class="tag-link">systemd</a><a href="#" class="tag-link">tls</a><a href="#" class="tag-link">selfhosted</a><a href="#" class="tag-link">ubuntu</a><a href="#" class="tag-link">bash</a>
        </div>
      </div>
    </div>
  </aside>
</div>
<footer>
  <div class="footer-inner">
    <div class="footer-left"><span>&gt;_ DevStack</span> · Built with Caddy · © 2026</div>
    <div class="footer-links"><a href="#">Archive</a><a href="#">RSS</a><a href="#">Privacy</a><a href="#">Contact</a></div>
  </div>
</footer>
</body>
</html>
CAMOUFLAGE_EOF

    chmod 644 "$WEBROOT/index.html"
    ok "Камуфляжная страница установлена → $WEBROOT/index.html"
}

# ─── Caddyfile ───────────────────────────────────────────────
write_caddyfile() {
    mkdir -p "$CADDY_DIR" "$WEBROOT" "$LOG_DIR"

    install_camouflage_page

    # Собираем блоки basic_auth
    local auth_blocks=""
    while IFS=: read -r u p; do
        [[ -z "$u" ]] && continue
        auth_blocks+="        basic_auth ${u} ${p}"$'\n'
    done < <(get_users)

    cat > "$CADDYFILE" <<EOF
{
    order forward_proxy before file_server
    servers :443 {
        protocols h1 h2 h3
    }
    log {
        output file ${LOG_DIR}/access.log {
            roll_size 50mb
            roll_keep 3
        }
    }
}

:443, ${DOMAIN} {
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

# Авто-перезапуск при сбое
Restart=on-failure
RestartSec=5s
StartLimitBurst=5
StartLimitIntervalSec=60

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable caddy --quiet
    ok "systemd сервис Caddy настроен (Restart=on-failure)"
}

# ─── UFW ─────────────────────────────────────────────────────
setup_firewall() {
    command -v ufw &>/dev/null || apt-get install -y -q ufw
    info "Настраиваю UFW..."

    # Включаем UFW если не активен
    if ! ufw status | grep -q "Status: active"; then
        # Дефолтная политика: блокируем всё входящее
        ufw default deny incoming  >/dev/null 2>&1 || true
        ufw default allow outgoing >/dev/null 2>&1 || true
        ufw --force enable >/dev/null 2>&1 || true
        ok "UFW включён (дефолт: блокировать всё входящее)"
    fi

    # Базовые порты NaiveProxy
    ufw allow 80/tcp  comment "NaiveProxy ACME"  >/dev/null 2>&1 || true
    ufw allow 443/tcp comment "NaiveProxy HTTPS" >/dev/null 2>&1 || true
    ufw allow 443/udp comment "NaiveProxy HTTP3" >/dev/null 2>&1 || true

    # Лимит подключений — защита от DDoS и сканирования
    ufw allow 80/tcp  >/dev/null 2>&1 || true

    # Блокируем типичные порты для сканеров
    for port in 3306 5432 6379 27017 8080 8888 9200; do
        ufw deny "${port}/tcp" comment "Block scanners" >/dev/null 2>&1 || true
    done

    ok "UFW: открыты 80, 443/tcp, 443/udp"
    ok "UFW: заблокированы порты БД и типичные цели сканеров"
    ok "UFW: лимит на 80/tcp для защиты от DDoS"
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
    # QR код для быстрого подключения
    echo
    info "QR код для быстрого подключения с телефона:"
    local uri="naive+https://${first_user}:${first_pass}@${DOMAIN}:443"
    if command -v qrencode &>/dev/null; then
        echo
        qrencode -t ANSIUTF8 "$uri"
        echo
    else
        info "Устанавливаю qrencode для QR кода..."
        apt-get install -y -q qrencode 2>/dev/null &&         echo && qrencode -t ANSIUTF8 "$uri" && echo ||         warn "qrencode недоступен — установи вручную: apt install qrencode"
    fi
    ok "Отсканируй QR в NekoBox / Shadowrocket"
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


# ─── УПРАВЛЕНИЕ ДОМЕНАМИ ─────────────────────────────────────
cmd_domains() {
    load_config

    while true; do
        hr
        echo -e "${BOLD}  Управление доменами${RESET}"
        hr

        local current_domains="${DOMAINS:-${DOMAIN:-}}"
        echo -e "  ${BOLD}Текущие домены:${RESET}"
        local i=1
        IFS=',' read -ra dlist <<< "$current_domains"
        for d in "${dlist[@]}"; do
            d="${d// /}"
            [[ -n "$d" ]] && echo -e "  ${i}. ${CYAN}${d}${RESET}" && ((i++))
        done
        echo
        echo -e "  ${BOLD}1)${RESET} Добавить домен"
        echo -e "  ${BOLD}2)${RESET} Удалить домен"
        echo -e "  ${BOLD}0)${RESET} Назад"
        hr
        echo -ne "${CYAN}Выбор: ${RESET}"
        read -r choice; echo

        case "$choice" in
            1)
                echo -ne "${CYAN}Новый домен: ${RESET}"
                read -r new_dom
                if [[ ! "$new_dom" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
                    err "Неверный формат домена"
                    continue
                fi
                check_domain "$new_dom"
                if [[ -z "$DOMAINS" ]]; then
                    DOMAINS="${DOMAIN:-}"
                fi
                DOMAINS="${DOMAINS},${new_dom}"
                # Убираем ведущую запятую
                DOMAINS="${DOMAINS#,}"
                save_config
                backup_config
                write_caddyfile_multi
                systemctl reload caddy 2>/dev/null || systemctl restart caddy
                ok "Домен $new_dom добавлен"
                tg_send "🌐 <b>Добавлен домен</b>: <code>${new_dom}</code>"
                ;;
            2)
                # Защита: считаем сколько доменов
                local _dom_total
                _dom_total=$(echo "$current_domains" | tr ',' '\n' | grep -c '\S' || echo 0)
                if [[ ${_dom_total} -le 1 ]]; then
                    err "❌ Нельзя удалить последний домен!"
                    err "Сервер перестанет работать без домена."
                    err "Сначала добавь новый домен (вариант 1), потом удаляй старый."
                    echo -ne "${YELLOW}Enter для продолжения...${RESET}"; read -r
                    continue
                fi
                echo -ne "${CYAN}Номер домена для удаления: ${RESET}"
                read -r del_idx
                local new_domains=""
                local j=1
                IFS=',' read -ra dlist2 <<< "$current_domains"
                for d in "${dlist2[@]}"; do
                    d="${d// /}"
                    [[ -z "$d" ]] && continue
                    if [[ "$j" != "$del_idx" ]]; then
                        new_domains="${new_domains},${d}"
                    fi
                    ((j++))
                done
                DOMAINS="${new_domains#,}"
                DOMAIN=$(echo "$DOMAINS" | cut -d',' -f1)
                save_config
                backup_config
                write_caddyfile_multi
                systemctl reload caddy 2>/dev/null || systemctl restart caddy
                ok "Домен удалён"
                ;;
            0) break ;;
            *) warn "Неверный выбор" ;;
        esac

        echo -ne "${YELLOW}Enter для продолжения...${RESET}"; read -r
    done
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
                elif [[ "$new_pass" == *":"* ]]; then
                    err "Пароль не может содержать символ ':'"
                    continue
                fi
                printf '%s:%s
' "${new_user}" "${new_pass}" >> "$USERS_FILE"
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
                # grep -F для фиксированной строки — защита от regex в имени
                grep -vF "${del_user}:" "$USERS_FILE" > "${USERS_FILE}.tmp" && mv "${USERS_FILE}.tmp" "$USERS_FILE" || true
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
                elif [[ "$chg_pass" == *":"* ]]; then
                    err "Пароль не может содержать символ ':'"; continue
                fi
                backup_config
                # Безопасная замена без sed regex
                local tmp_users
                tmp_users=$(mktemp)
                trap 'rm -f "${tmp_users:-}" 2>/dev/null' RETURN
                while IFS=: read -r u p; do
                    if [[ "$u" == "$chg_user" ]]; then
                        printf '%s:%s
' "$u" "$chg_pass"
                    else
                        printf '%s:%s
' "$u" "$p"
                    fi
                done < "$USERS_FILE" > "$tmp_users" && mv "$tmp_users" "$USERS_FILE"
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


# ══════════════════════════════════════════════════════════════
#   SELF-UPDATE СКРИПТА
# ══════════════════════════════════════════════════════════════

cmd_self_update() {
    hr
    echo -e "${BOLD}  Обновление скрипта NaiveProxy Manager${RESET}"
    hr

    info "Текущая версия: ${BOLD}v${VERSION}${RESET}"
    info "Проверяю последнюю версию на GitHub..."

    # Получаем последнюю версию через GitHub API
    local latest_ver
    latest_ver=$(curl -s --max-time 10 "$GITHUB_API" 2>/dev/null         | grep '"tag_name"'         | grep -oP '"\K[^"]+'         | head -1         | tr -d 'v' || echo "")

    if [[ -z "$latest_ver" ]]; then
        # Fallback: читаем VERSION из raw скрипта
        latest_ver=$(curl -s --max-time 10 "$GITHUB_RAW" 2>/dev/null             | grep '^VERSION='             | grep -oP '"\K[^"]+' || echo "")
    fi

    if [[ -z "$latest_ver" ]]; then
        err "Не удалось получить версию с GitHub. Проверь интернет."
        return 1
    fi

    info "Последняя версия: ${BOLD}v${latest_ver}${RESET}"

    if [[ "$latest_ver" == "$VERSION" ]]; then
        ok "У тебя уже последняя версия v${VERSION}"
        return 0
    fi

    echo
    echo -e "  ${YELLOW}Доступно обновление: v${VERSION} → v${latest_ver}${RESET}"
    echo -ne "${CYAN}Обновить? [Y/n]: ${RESET}"
    read -r ans
    [[ "${ans,,}" == "n" ]] && return 0

    # Скачиваем новую версию во временный файл
    local tmp_script
    tmp_script=$(mktemp /tmp/naiveproxy_update_XXXXXX.sh)
    # Cleanup при любом выходе из функции
    trap 'rm -f "${tmp_script:-}" 2>/dev/null' RETURN

    info "Скачиваю v${latest_ver}..."
    if ! curl -fsSL --max-time 60 "$GITHUB_RAW" -o "$tmp_script" 2>/dev/null; then
        err "Ошибка загрузки скрипта"
        rm -f "$tmp_script"
        return 1
    fi

    # Проверяем что скачали валидный bash скрипт
    if ! bash -n "$tmp_script" 2>/dev/null; then
        err "Скачанный скрипт содержит ошибки синтаксиса! Отменяю обновление."
        rm -f "$tmp_script"
        return 1
    fi

    # Проверяем что это действительно наш скрипт
    if ! grep -q "NaiveProxy Manager" "$tmp_script" 2>/dev/null; then
        err "Скачанный файл не является NaiveProxy Manager. Отменяю."
        rm -f "$tmp_script"
        return 1
    fi

    # Определяем куда установлен скрипт
    local current_script
    current_script=$(realpath "$0" 2>/dev/null || echo "")
    if [[ -z "$current_script" || "$current_script" == /dev/fd/* || "$current_script" == /proc/* ]]; then
        current_script="$SCRIPT_PATH"
    fi

    # Бэкап текущей версии
    local backup_path="${current_script}.v${VERSION}.bak"
    cp "$current_script" "$backup_path" 2>/dev/null || true
    ok "Бэкап текущей версии: $backup_path"

    # Устанавливаем новую версию
    chmod +x "$tmp_script"
    mv "$tmp_script" "$current_script"
    chmod +x "$current_script"

    # Обновляем в /usr/local/bin если там другое место
    if [[ "$current_script" != "$SCRIPT_PATH" ]]; then
        cp "$current_script" "$SCRIPT_PATH" 2>/dev/null || true
        chmod +x "$SCRIPT_PATH" 2>/dev/null || true
    fi

    ok "Скрипт обновлён: v${VERSION} → v${latest_ver}"
    tg_send "🔄 <b>NaiveProxy Manager обновлён</b>
📦 Было: <code>v${VERSION}</code>
📦 Стало: <code>v${latest_ver}</code>
🕐 $(date '+%Y-%m-%d %H:%M:%S')"

    echo
    info "Перезапускаю обновлённый скрипт..."
    sleep 1
    exec bash "$current_script"
}

# ── Тихая проверка обновлений при запуске ─────────────────────
check_update_available() {
    # Запускаем в фоне чтобы не тормозить старт
    (
        local latest_ver
        latest_ver=$(curl -s --max-time 5 "$GITHUB_RAW" 2>/dev/null             | grep '^VERSION='             | grep -oP '"\K[^"]+' || echo "")
        if [[ -n "$latest_ver" && "$latest_ver" != "$VERSION" ]]; then
            echo -e "\n  ${YELLOW}⬆  Доступно обновление скрипта: v${VERSION} → v${latest_ver}${RESET}"
            echo -e "  ${YELLOW}   Меню → 13) Обновить скрипт${RESET}\n"
        fi
    ) &
}


# ─── ДИАГНОСТИКА СИСТЕМЫ ──────────────────────────────────────
cmd_diagnose() {
    load_config 2>/dev/null || true

    local pass=0 warn=0 fail=0
    local report=""

    # Хелперы вывода — используем pass+=1 вместо pass=$((pass+1)) из-за set -e
    _ok()   { echo -e "  ${GREEN}✅ $1${RESET}";   report+="✅ $1\n"; pass=$((pass+1)); }
    _warn() { echo -e "  ${YELLOW}⚠️  $1${RESET}"; report+="⚠️  $1\n"; warn=$((warn+1)); }
    _fail() { echo -e "  ${RED}❌ $1${RESET}";    report+="❌ $1\n"; fail=$((fail+1)); }
    _info() { echo -e "  ${CYAN}ℹ️  $1${RESET}"; }
    _sep()  { echo -e "  ${DIM}──────────────────────────────────────${RESET}"; }

    hr
    echo -e "${BOLD}  🔍 Диагностика NaiveProxy Manager v${VERSION}${RESET}"
    echo -e "  $(date '+%Y-%m-%d %H:%M:%S') · $(hostname)"
    hr
    echo

    # ── БЛОК 1: CADDY ─────────────────────────────────────────
    echo -e "  ${BOLD}[1/7] Caddy${RESET}"
    _sep

    # Caddy существует
    if [[ -f "${CADDY_BIN}" ]]; then
        local caddy_ver
        caddy_ver=$("${CADDY_BIN}" version 2>/dev/null | head -1 || echo "неизвестно")
        _ok "Caddy найден: ${caddy_ver}"
    else
        _fail "Caddy не найден: ${CADDY_BIN}"
    fi

    # Caddy запущен
    if systemctl is-active caddy &>/dev/null; then
        local uptime_caddy
        uptime_caddy=$(systemctl show caddy --property=ActiveEnterTimestamp             | cut -d= -f2 | xargs -I{} date -d "{}" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "н/д")
        _ok "Caddy запущен (с ${uptime_caddy})"
    else
        _fail "Caddy НЕ запущен! Запусти: systemctl start caddy"
    fi

    # Naive padding в бинарнике
    if ! command -v strings &>/dev/null; then
        info "Устанавливаю binutils для проверки padding..."
        apt-get install -y -q binutils 2>/dev/null || true
    fi
    if command -v strings &>/dev/null && [[ -f "${CADDY_BIN}" ]]; then
        # Проверяем naive padding по нескольким признакам
        local _pad_count
        _pad_count=$(strings "${CADDY_BIN}" 2>/dev/null | grep -cE "^(Padding|SetPadding|WithPadding|writePadding|PaddingLength)$" || true)
        _pad_count="${_pad_count//[^0-9]/}"
        _pad_count="${_pad_count:-0}"
        if [[ "${_pad_count}" -ge 2 ]]; then
            _ok "Naive padding модуль подтверждён (${_pad_count} символов)"
        else
            _fail "Naive padding НЕ найден в Caddy — пересобери: sudo bash naiveproxy.sh update"
        fi
    else
        _warn "strings недоступен — установи: apt install binutils"
    fi

    # forward_proxy модуль
    if "${CADDY_BIN}" list-modules 2>/dev/null | grep -q "forward_proxy"; then
        _ok "Модуль forward_proxy загружен"
    else
        _fail "Модуль forward_proxy НЕ найден"
    fi

    echo

    # ── БЛОК 2: CADDYFILE ─────────────────────────────────────
    echo -e "  ${BOLD}[2/7] Конфигурация${RESET}"
    _sep

    if [[ -f "${CADDYFILE}" ]]; then
        _ok "Caddyfile найден: ${CADDYFILE}"

        # Правильный порядок :443, domain
        if grep -q "^:443," "${CADDYFILE}"; then
            _ok "Caddyfile: правильный формат ':443, domain'"
        elif grep -qE "^\S+:443" "${CADDYFILE}"; then
            _fail "Caddyfile: НЕПРАВИЛЬНЫЙ формат 'domain:443' — исправь на ':443, domain'"
        fi

        # order forward_proxy
        if grep -q "order forward_proxy before file_server" "${CADDYFILE}"; then
            _ok "Caddyfile: order forward_proxy — OK"
        else
            _warn "Caddyfile: отсутствует 'order forward_proxy before file_server'"
        fi

        # probe_resistance
        if grep -q "probe_resistance" "${CADDYFILE}"; then
            _ok "probe_resistance включён"
        else
            _warn "probe_resistance отключён — сервер видим для сканеров"
        fi

        # Пользователи
        local user_count=0
        [[ -f "${USERS_FILE}" ]] && user_count=$(grep -c "." "${USERS_FILE}" 2>/dev/null || echo 0)
        if [[ ${user_count} -gt 0 ]]; then
            _ok "Пользователей: ${user_count}"
        else
            _fail "Нет пользователей! Добавь: sudo bash naiveproxy.sh users"
        fi

        # Caddy validate
        if "${CADDY_BIN}" validate --config "${CADDYFILE}" &>/dev/null; then
            _ok "Caddyfile валиден (caddy validate passed)"
        else
            _fail "Ошибка в Caddyfile! Проверь: caddy validate --config ${CADDYFILE}"
        fi
    else
        _fail "Caddyfile не найден: ${CADDYFILE}"
    fi

    echo

    # ── БЛОК 3: TLS / СЕТЬ ────────────────────────────────────
    echo -e "  ${BOLD}[3/7] TLS и сеть${RESET}"
    _sep

    local domain="${DOMAIN:-}"

    if [[ -z "${domain}" ]]; then
        _warn "Домен не настроен — пропускаю сетевые проверки"
    else
        _info "Домен: ${domain}"

        # DNS → IP
        local dns_ip server_ip
        dns_ip=$(dig +short "${domain}" 2>/dev/null | grep -E '^[0-9]+\.' | head -1 || echo "")
        server_ip=$(curl -s4 --max-time 5 https://ifconfig.me 2>/dev/null                  || curl -s4 --max-time 5 https://api.ipify.org 2>/dev/null || echo "")

        if [[ -z "${dns_ip}" ]]; then
            _fail "DNS не резолвится для ${domain}"
        elif [[ "${dns_ip}" == "${server_ip}" ]]; then
            _ok "DNS: ${domain} → ${dns_ip} (совпадает с IP сервера)"
        else
            _fail "DNS: ${domain} → ${dns_ip} НЕ совпадает с IP сервера ${server_ip}"
        fi

        # Порт 80
        if ss -tlnp | grep -q ":80 "; then
            _ok "Порт 80 слушается (ACME)"
        else
            _warn "Порт 80 не слушается — Let's Encrypt может не работать"
        fi

        # Порт 443
        if ss -tlnp | grep -q ":443 "; then
            _ok "Порт 443 слушается"
        else
            _fail "Порт 443 не слушается!"
        fi

        # ALPN h2
        local alpn
        alpn=$(echo | timeout 8 openssl s_client \
            -connect "${domain}:443" \
            -alpn h2 \
            -servername "${domain}" \
            2>/dev/null | grep "ALPN protocol" | awk '{print $3}')
        alpn="${alpn//[^a-z0-9]/}"  # убираем лишние символы
        if [[ "${alpn}" == "h2" ]]; then
            _ok "ALPN: h2 ✓ (HTTP/2 работает)"
        else
            _warn "ALPN: не h2 (получено: '${alpn}') — возможно сервер за NAT или firewall"
        fi

        # TLS сертификат
        local cert_days=0
        local cert_info
        cert_info=$(echo | timeout 8 openssl s_client \
            -connect "${domain}:443" \
            -servername "${domain}" \
            2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "")
        if [[ -n "${cert_info}" ]]; then
            local not_after expire_ts now_ts
            not_after=$(echo "${cert_info}" | grep "notAfter" | cut -d= -f2)
            expire_ts=$(date -d "${not_after}" +%s 2>/dev/null || echo 0)
            now_ts=$(date +%s)
            cert_days=$(( (expire_ts - now_ts) / 86400 ))
            if [[ ${cert_days} -gt 30 ]]; then
                _ok "TLS сертификат действителен ещё ${cert_days} дней"
            elif [[ ${cert_days} -gt 7 ]]; then
                _warn "TLS сертификат истекает через ${cert_days} дней"
            else
                _fail "TLS сертификат истекает через ${cert_days} дней! Срочно!"
            fi
        else
            _fail "Не удалось получить TLS сертификат для ${domain}"
        fi
    fi

    echo

    # ── БЛОК 4: FIREWALL ──────────────────────────────────────
    echo -e "  ${BOLD}[4/7] Firewall${RESET}"
    _sep

    # UFW
    if command -v ufw &>/dev/null; then
        if ufw status | grep -q "Status: active"; then
            _ok "UFW активен"
            # Проверяем нужные порты
            for port in "80/tcp" "443/tcp" "443/udp"; do
                if ufw status | grep -q "${port}"; then
                    _ok "UFW: порт ${port} открыт"
                else
                    _warn "UFW: порт ${port} НЕ открыт"
                fi
            done
        else
            _fail "UFW неактивен! Включи: ufw enable"
        fi
    else
        _warn "UFW не установлен"
    fi

    # Fail2Ban
    if systemctl is-active fail2ban &>/dev/null; then
        local banned_count
        banned_count=$(fail2ban-client status sshd 2>/dev/null             | grep "Currently banned" | awk '{print $NF}' || echo "0")
        _ok "Fail2Ban активен (сейчас забанено SSH: ${banned_count})"
    else
        _warn "Fail2Ban не запущен — SSH не защищён от брутфорса"
    fi

    echo

    # ── БЛОК 5: РЕСУРСЫ ───────────────────────────────────────
    echo -e "  ${BOLD}[5/7] Ресурсы системы${RESET}"
    _sep

    # RAM
    local ram_used ram_total ram_pct
    ram_used=$(free -m | awk '/Mem:/{print $3}')
    ram_total=$(free -m | awk '/Mem:/{print $2}')
    ram_pct=$(( ram_used * 100 / ram_total ))
    if [[ ${ram_pct} -lt 80 ]]; then
        _ok "RAM: ${ram_used}/${ram_total} MB (${ram_pct}%)"
    elif [[ ${ram_pct} -lt 95 ]]; then
        _warn "RAM: ${ram_used}/${ram_total} MB (${ram_pct}%) — высокое потребление"
    else
        _fail "RAM: ${ram_used}/${ram_total} MB (${ram_pct}%) — критически мало!"
    fi

    # Диск
    local disk_used disk_total disk_pct
    disk_pct=$(df / | awk 'NR==2{print $5}' | tr -d '%')
    disk_used=$(df -h / | awk 'NR==2{print $3}')
    disk_total=$(df -h / | awk 'NR==2{print $2}')
    if [[ ${disk_pct} -lt 80 ]]; then
        _ok "Диск: ${disk_used}/${disk_total} (${disk_pct}%)"
    elif [[ ${disk_pct} -lt 95 ]]; then
        _warn "Диск: ${disk_used}/${disk_total} (${disk_pct}%) — мало места"
    else
        _fail "Диск: ${disk_used}/${disk_total} (${disk_pct}%) — критически мало!"
    fi

    # Load average
    local load
    load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    local cpus
    cpus=$(nproc)
    local load_pct
    load_pct=$(echo "${load} ${cpus}" | awk '{printf "%d", ($1/$2)*100}')
    if [[ ${load_pct} -lt 80 ]]; then
        _ok "Нагрузка CPU: ${load} (${load_pct}% от ${cpus} ядер)"
    else
        _warn "Нагрузка CPU: ${load} (${load_pct}%) — высокая"
    fi

    echo

    # ── БЛОК 6: ЛОГИ ──────────────────────────────────────────
    echo -e "  ${BOLD}[6/7] Анализ логов${RESET}"
    _sep

    local log_errors=0
    if [[ -f "${LOG_DIR}/access.log" ]]; then
        # Считаем ошибки за последние 100 строк
        log_errors=$(tail -100 "${LOG_DIR}/access.log" 2>/dev/null \
            | python3 -c "
import sys,json
errs=0
for line in sys.stdin:
    try:
        d=json.loads(line)
        if d.get('status',200) >= 500: errs+=1
    except: pass
print(errs)
" 2>/dev/null || true)
        log_errors="${log_errors//[^0-9]/}"
        log_errors="${log_errors:-0}"

        local connect_count
        connect_count=$(tail -100 "${LOG_DIR}/access.log" 2>/dev/null \
            | grep -c '"CONNECT"' 2>/dev/null || true)
        connect_count="${connect_count//[^0-9]/}"
        connect_count="${connect_count:-0}"

        if [[ ${log_errors} -eq 0 ]]; then
            _ok "Логи: нет серверных ошибок (последние 100 запросов)"
        else
            _warn "Логи: ${log_errors} ошибок в последних 100 запросах"
        fi
        _info "CONNECT туннелей в последних 100 записях: ${connect_count}"
    else
        _warn "Лог файл не найден: ${LOG_DIR}/access.log"
    fi

    # Ошибки Caddy в journald
    local caddy_errors
    caddy_errors=$(journalctl -u caddy -n 50 --no-pager 2>/dev/null \
        | grep -ci "error\|panic\|fatal" 2>/dev/null || true)
    caddy_errors="${caddy_errors//[^0-9]/}"  # оставляем только цифры
    caddy_errors="${caddy_errors:-0}"
    if [[ "${caddy_errors}" -eq 0 ]]; then
        _ok "journald: нет критических ошибок Caddy"
    else
        _warn "journald: найдено ${caddy_errors} строк с ошибками — проверь: journalctl -u caddy -n 50"
    fi

    echo

    # ── БЛОК 7: ВЕРСИЯ И ОБНОВЛЕНИЯ ───────────────────────────
    echo -e "  ${BOLD}[7/7] Версия и обновления${RESET}"
    _sep

    _info "Текущая версия скрипта: v${VERSION}"

    local latest_ver
    latest_ver=$(curl -s --max-time 8 "${GITHUB_RAW}" 2>/dev/null         | grep '^VERSION=' | grep -oP '"\K[^"]+' || echo "")

    if [[ -n "${latest_ver}" ]]; then
        if [[ "${latest_ver}" == "${VERSION}" ]]; then
            _ok "Скрипт актуален: v${VERSION}"
        else
            _warn "Доступно обновление: v${VERSION} → v${latest_ver} (меню → 14)"
        fi
    else
        _warn "Не удалось проверить обновления"
    fi

    # SSH Hardening выполнен?
    if [[ -f "${SSH_HARDENING_DONE}" ]]; then
        local ssh_port_saved
        ssh_port_saved=$(grep SSH_PORT "${SSH_HARDENING_DONE}" 2>/dev/null | cut -d= -f2 || echo "н/д")
        _ok "SSH Hardening выполнен (порт: ${ssh_port_saved})"
    else
        _warn "SSH Hardening не выполнен — рекомендуется: меню → 12"
    fi

    # ── ИТОГ ──────────────────────────────────────────────────
    echo
    hr
    echo -e "  ${BOLD}📊 ИТОГ ДИАГНОСТИКИ${RESET}"
    hr
    echo -e "  ${GREEN}✅ Пройдено:  ${pass}${RESET}"
    echo -e "  ${YELLOW}⚠️  Внимание: ${warn}${RESET}"
    echo -e "  ${RED}❌ Проблемы: ${fail}${RESET}"
    echo

    if [[ ${fail} -eq 0 && ${warn} -eq 0 ]]; then
        echo -e "  ${GREEN}${BOLD}🎉 Всё работает отлично!${RESET}"
    elif [[ ${fail} -eq 0 ]]; then
        echo -e "  ${YELLOW}${BOLD}⚠️  Есть предупреждения — рекомендуется проверить${RESET}"
    else
        echo -e "  ${RED}${BOLD}❌ Найдены проблемы — требуется вмешательство${RESET}"
    fi

    hr

    # Отправляем отчёт в Telegram если настроен
    echo -ne "\n${YELLOW}Отправить отчёт в Telegram? [y/N]: ${RESET}"
    read -r ans
    if [[ "${ans,,}" == "y" ]]; then
        tg_send "🔍 <b>Диагностика NaiveProxy</b>
🖥 Сервер: <code>$(hostname)</code>
🕐 $(date '+%Y-%m-%d %H:%M:%S')

${report}
✅ Пройдено: ${pass}  ⚠️ Внимание: ${warn}  ❌ Проблемы: ${fail}"
        ok "Отчёт отправлен в Telegram"
    fi
}


# ══════════════════════════════════════════════════════════════
#   TELEGRAM BOT — ИНТЕРАКТИВНОЕ УПРАВЛЕНИЕ
# ══════════════════════════════════════════════════════════════

# Проверка что пользователь является администратором
tg_is_admin() {
    local from_id="$1"
    # Валидация: from_id должен быть числом
    [[ ! "${from_id}" =~ ^[0-9]+$ ]] && return 1
    # Основной admin
    [[ "${from_id}" == "${TG_CHAT_ID}" ]] && return 0
    # Дополнительные admins
    if [[ -n "${TG_ADMINS:-}" ]]; then
        local IFS=','
        for admin_id in ${TG_ADMINS}; do
            admin_id="${admin_id// /}"
            [[ "${from_id}" == "${admin_id}" ]] && return 0
        done
    fi
    return 1
}

# Отправка сообщения конкретному chat_id
tg_reply() {
    local chat_id="$1"
    local message="$2"
    [[ -z "${TG_TOKEN:-}" ]] && return
    curl -s --max-time 10         -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage"         --data-urlencode "chat_id=${chat_id}"         --data-urlencode "parse_mode=HTML"         --data-urlencode "text=${message}"         >/dev/null 2>&1 || true
}

# Отправка фото (QR код)
tg_send_photo() {
    local chat_id="$1"
    local photo_path="$2"
    local caption="$3"
    [[ -z "${TG_TOKEN:-}" || ! -f "${photo_path}" ]] && return
    # Используем только -F для multipart (-F и --data-urlencode несовместимы)
    curl -s --max-time 30 \
        -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendPhoto" \
        -F "chat_id=${chat_id}" \
        -F "caption=${caption}" \
        -F "photo=@${photo_path}" \
        >/dev/null 2>&1 || true
}

# Обработка одной команды
tg_handle_command() {
    local chat_id="$1"
    local from_id="$2"
    local text="$3"

    # Отключаем строгий режим внутри обработчика — иначе любая ошибка ломает бот
    set +e

    # Проверка прав
    if ! tg_is_admin "${from_id}"; then
        tg_reply "${chat_id}" "⛔ <b>Доступ запрещён</b>
Ваш ID: <code>${from_id}</code>
Обратитесь к администратору."
        return
    fi

    load_config 2>/dev/null || true

    # Очищаем text от \r \n и невидимых символов
    text="${text//$'\r'/}"
    text="${text//$'\n'/}"

    # Лимит длины команды — защита от flood/injection
    if [[ ${#text} -gt 256 ]]; then
        tg_reply "${chat_id}" "❌ Команда слишком длинная"
        return
    fi

    # Парсим команду и аргументы
    local cmd args
    cmd=$(echo "${text}" | awk '{print $1}' | tr '[:upper:]' '[:lower:]' | tr -d '\r\n[:cntrl:]')
    # args = всё после первого пробела
    if [[ "${text}" == *" "* ]]; then
        args="${text#* }"
        # Trim leading/trailing whitespace
        args="${args#"${args%%[![:space:]]*}"}"
        args="${args%"${args##*[![:space:]]}"}"
    else
        args=""
    fi
    # Убираем потенциально опасные символы из args (но оставляем безопасные)
    args=$(echo "${args}" | tr -d '`$();<>&|\\')

    case "${cmd}" in

        /start|/help)
            tg_reply "${chat_id}" "🛡 <b>NaiveProxy Manager v${VERSION}</b>
🖥 Сервер: <code>$(hostname)</code>

<b>Доступные команды:</b>

📊 <b>Информация</b>
/status — статус сервера и сертификата
/stats — статистика трафика и ресурсов
/diagnose — полная диагностика системы
/logs — последние 20 строк логов
/users — список пользователей
/cert — статус TLS сертификата

👥 <b>Пользователи</b>
/adduser логин пароль — добавить пользователя
/deluser логин — удалить пользователя
/qr логин — QR код для подключения

⚙️ <b>Управление</b>
/restart — перезапустить Caddy
/update — обновить Caddy
/selfupdate — обновить скрипт
/admins — список администраторов
/addadmin ID — добавить администратора
/deladmin ID — удалить администратора"
            ;;

        /status)
            local caddy_status="🔴 Остановлен"
            systemctl is-active caddy &>/dev/null && caddy_status="🟢 Работает"

            local cert_info=""
            if [[ -n "${DOMAIN:-}" ]]; then
                local not_after expire_ts now_ts cert_days
                not_after=$(echo | timeout 5 openssl s_client                     -connect "${DOMAIN}:443" -servername "${DOMAIN}" 2>/dev/null                     | openssl x509 -noout -dates 2>/dev/null                     | grep "notAfter" | cut -d= -f2 || echo "")
                if [[ -n "${not_after}" ]]; then
                    expire_ts=$(date -d "${not_after}" +%s 2>/dev/null || echo 0)
                    now_ts=$(date +%s)
                    cert_days=$(( (expire_ts - now_ts) / 86400 ))
                    cert_info="
🔐 Сертификат: ${cert_days} дней"
                fi
            fi

            tg_reply "${chat_id}" "📡 <b>Статус NaiveProxy</b>
🖥 Сервер: <code>$(hostname)</code>
${caddy_status}
🌐 Домен: <code>${DOMAIN:-не настроен}</code>
👥 Пользователей: $(get_users | wc -l)
💾 RAM: $(free -h | awk '/Mem:/{print $3"/"$2}')
💿 Диск: $(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')
🕐 $(date '+%Y-%m-%d %H:%M:%S')${cert_info}"
            ;;

        /stats)
            tg_send_stats_to "${chat_id}"
            ;;

        /diagnose)
            tg_reply "${chat_id}" "🔍 Запускаю диагностику, подожди..."
            local diag_result=""
            local pass=0 warn=0 fail=0

            # Caddy
            if systemctl is-active caddy &>/dev/null; then
                diag_result+="✅ Caddy запущен
"
                pass=$((pass+1))
            else
                diag_result+="❌ Caddy НЕ запущен
"
                fail=$((fail+1))
            fi

            # Padding
            local _p
            _p=$(strings /usr/local/bin/caddy 2>/dev/null | grep -cE "^(Padding|SetPadding|WithPadding)$" || true)
            _p="${_p//[^0-9]/}"; _p="${_p:-0}"
            if command -v strings &>/dev/null && [[ "${_p}" -ge 2 ]]; then
                diag_result+="✅ Naive padding OK
"
                pass=$((pass+1))
            else
                diag_result+="⚠️ Padding не проверен
"
                warn=$((warn+1))
            fi

            # Caddyfile
            if grep -q "^:443," "${CADDYFILE:-/etc/caddy/Caddyfile}" 2>/dev/null; then
                diag_result+="✅ Caddyfile формат OK
"
                pass=$((pass+1))
            else
                diag_result+="❌ Caddyfile неправильный формат
"
                fail=$((fail+1))
            fi

            # ALPN
            if [[ -n "${DOMAIN:-}" ]]; then
                local alpn
                alpn=$(echo | timeout 5 openssl s_client                     -connect "${DOMAIN}:443" -alpn h2 2>/dev/null                     | grep "ALPN protocol" | awk '{print $3}' || echo "")
                if [[ "${alpn}" == "h2" ]]; then
                    diag_result+="✅ ALPN h2 OK
"
                    pass=$((pass+1))
                else
                    diag_result+="❌ ALPN не h2
"
                    fail=$((fail+1))
                fi
            fi

            # UFW
            if ufw status 2>/dev/null | grep -q "Status: active"; then
                diag_result+="✅ UFW активен
"
                pass=$((pass+1))
            else
                diag_result+="⚠️ UFW неактивен
"
                warn=$((warn+1))
            fi

            # Fail2Ban
            if systemctl is-active fail2ban &>/dev/null; then
                diag_result+="✅ Fail2Ban активен
"
                pass=$((pass+1))
            else
                diag_result+="⚠️ Fail2Ban не запущен
"
                warn=$((warn+1))
            fi

            # RAM
            local ram_pct
            ram_pct=$(free | awk '/Mem:/{printf "%d", $3/$2*100}')
            if [[ ${ram_pct} -lt 90 ]]; then
                diag_result+="✅ RAM: ${ram_pct}%
"
                pass=$((pass+1))
            else
                diag_result+="❌ RAM критически: ${ram_pct}%
"
                fail=$((fail+1))
            fi

            tg_reply "${chat_id}" "🔍 <b>Диагностика NaiveProxy</b>

${diag_result}
✅ Пройдено: ${pass}  ⚠️ Внимание: ${warn}  ❌ Проблемы: ${fail}"
            ;;

        /logs)
            local log_lines
            log_lines=$(journalctl -u caddy -n 20 --no-pager 2>/dev/null                 | tail -20 | sed 's/</\&lt;/g; s/>/\&gt;/g' || echo "Логи недоступны")
            tg_reply "${chat_id}" "📋 <b>Логи Caddy (последние 20):</b>
<pre>${log_lines}</pre>"
            ;;

        /users)
            local user_list
            user_list=$(get_users | awk -F: '{print "• <code>"$1"</code>"}' | head -20 || echo "Нет пользователей")
            tg_reply "${chat_id}" "👥 <b>Пользователи ($(get_users | wc -l)):</b>
${user_list}"
            ;;

        /adduser)
            local new_user new_pass
            new_user=$(echo "${args}" | awk '{print $1}')
            new_pass=$(echo "${args}" | awk '{print $2}')

            if [[ -z "${new_user}" ]]; then
                tg_reply "${chat_id}" "❌ Использование: /adduser логин пароль
Пример: /adduser alice MyPass123"
                return
            fi

            # Валидация логина
            if ! [[ "${new_user}" =~ ^[a-zA-Z0-9_-]{2,32}$ ]]; then
                tg_reply "${chat_id}" "❌ Неверный логин <code>${new_user}</code>
Только буквы, цифры, _, - (2-32 символа)"
                return
            fi

            # Валидация пароля (если указан)
            if [[ -z "${new_pass}" ]]; then
                # Авто-генерация
                new_pass=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9_-' | head -c 20)
                tg_reply "${chat_id}" "🔑 Пароль не указан, сгенерирован автоматически"
            elif [[ "${new_pass}" == *":"* ]]; then
                tg_reply "${chat_id}" "❌ Пароль не может содержать ':'"
                return
            elif [[ ${#new_pass} -lt 8 ]]; then
                tg_reply "${chat_id}" "❌ Пароль слишком короткий (минимум 8 символов)
Текущий: ${#new_pass} символов"
                return
            fi

            if get_users | grep -q "^${new_user}:"; then
                tg_reply "${chat_id}" "❌ Пользователь <code>${new_user}</code> уже существует"
                return
            fi

            # Создаём папку и файл если нет
            mkdir -p "$(dirname "${USERS_FILE}")"
            touch "${USERS_FILE}"
            chmod 600 "${USERS_FILE}"

            printf '%s:%s\n' "${new_user}" "${new_pass}" >> "${USERS_FILE}"

            if write_caddyfile 2>/dev/null; then
                systemctl reload caddy 2>/dev/null || systemctl restart caddy 2>/dev/null
                local uri="naive+https://${new_user}:${new_pass}@${DOMAIN}:443"
                tg_reply "${chat_id}" "✅ <b>Пользователь добавлен</b>
👤 Логин: <code>${new_user}</code>
🔑 Пароль: <code>${new_pass}</code>
🌐 URI:
<code>${uri}</code>

Используй /qr ${new_user} для QR кода"
            else
                tg_reply "${chat_id}" "⚠️ Пользователь добавлен но Caddyfile не обновлён"
            fi
            ;;

        /deluser)
            local del_user="${args%% *}"
            if [[ -z "${del_user}" ]]; then
                tg_reply "${chat_id}" "❌ Использование: /deluser логин"
                return
            fi

            if ! get_users | grep -q "^${del_user}:"; then
                tg_reply "${chat_id}" "❌ Пользователь <code>${del_user}</code> не найден"
                return
            fi

            grep -vF "${del_user}:" "${USERS_FILE}" > "${USERS_FILE}.tmp"                 && mv "${USERS_FILE}.tmp" "${USERS_FILE}"
            write_caddyfile
            systemctl reload caddy 2>/dev/null || systemctl restart caddy

            tg_reply "${chat_id}" "🗑 Пользователь <code>${del_user}</code> удалён"
            ;;

        /qr)
            local qr_user="${args%% *}"
            # Если args содержит ":" — значит это конкретный логин с двоеточием (не должно быть)
            if [[ -z "${qr_user}" ]]; then
                # QR для первого пользователя
                qr_user=$(get_users | head -1 | cut -d: -f1)
            fi

            if [[ -z "${qr_user}" ]]; then
                tg_reply "${chat_id}" "❌ Нет пользователей. Добавь: /adduser логин пароль"
                return
            fi

            local qr_pass
            qr_pass=$(get_users | grep "^${qr_user}:" | cut -d: -f2)

            if [[ -z "${qr_pass}" ]]; then
                tg_reply "${chat_id}" "❌ Пользователь <code>${qr_user}</code> не найден
Список пользователей: /users"
                return
            fi

            if [[ -z "${DOMAIN:-}" ]]; then
                tg_reply "${chat_id}" "❌ Домен не настроен в конфиге"
                return
            fi

            local uri="naive+https://${qr_user}:${qr_pass}@${DOMAIN}:443"

            # Авто-установка qrencode если нет
            if ! command -v qrencode &>/dev/null; then
                tg_reply "${chat_id}" "📦 Устанавливаю qrencode..."
                apt-get install -y -q qrencode &>/dev/null
            fi

            if command -v qrencode &>/dev/null; then
                local qr_file="/tmp/naiveproxy_qr_${qr_user}_$$.png"
                if qrencode -o "${qr_file}" -s 8 "${uri}" 2>/dev/null && [[ -s "${qr_file}" ]]; then
                    tg_send_photo "${chat_id}" "${qr_file}" "📱 QR для ${qr_user}@${DOMAIN}"
                    # Дополнительно отправляем URI текстом
                    tg_reply "${chat_id}" "🔗 <b>URI:</b>
<code>${uri}</code>"
                    rm -f "${qr_file}"
                else
                    tg_reply "${chat_id}" "⚠️ Ошибка генерации QR
🔗 URI: <code>${uri}</code>"
                fi
            else
                tg_reply "${chat_id}" "📱 <b>URI для ${qr_user}:</b>
<code>${uri}</code>
(установи qrencode на сервере для QR картинки)"
            fi
            ;;

        /cert)
            if [[ -z "${DOMAIN:-}" ]]; then
                tg_reply "${chat_id}" "❌ Домен не настроен"
                return
            fi
            local cert_out
            cert_out=$(echo | timeout 5 openssl s_client                 -connect "${DOMAIN}:443" -servername "${DOMAIN}" 2>/dev/null                 | openssl x509 -noout -dates -issuer 2>/dev/null || echo "")
            if [[ -z "${cert_out}" ]]; then
                tg_reply "${chat_id}" "❌ Не удалось получить сертификат для ${DOMAIN}"
                return
            fi
            local not_after issuer cert_days
            not_after=$(echo "${cert_out}" | grep "notAfter" | cut -d= -f2)
            issuer=$(echo "${cert_out}" | grep "issuer" | grep -oP 'O=\K[^,]+' || echo "н/д")
            expire_ts=$(date -d "${not_after}" +%s 2>/dev/null || echo 0)
            cert_days=$(( ($(date +%s) - expire_ts) / -86400 ))
            local cert_icon="🟢"
            [[ ${cert_days} -lt 30 ]] && cert_icon="🟡"
            [[ ${cert_days} -lt 7 ]] && cert_icon="🔴"
            tg_reply "${chat_id}" "${cert_icon} <b>TLS Сертификат</b>
🌐 Домен: <code>${DOMAIN}</code>
📅 Истекает: ${not_after}
⏳ Осталось: <b>${cert_days} дней</b>
🏢 Выдан: ${issuer}"
            ;;

        /restart)
            tg_reply "${chat_id}" "🔄 Перезапускаю Caddy..."
            if systemctl restart caddy 2>/dev/null; then
                sleep 2
                tg_reply "${chat_id}" "✅ Caddy перезапущен"
            else
                tg_reply "${chat_id}" "❌ Ошибка перезапуска. Проверь: journalctl -u caddy -n 20"
            fi
            ;;

        /update)
            tg_reply "${chat_id}" "🔄 Обновляю Caddy, подожди 5-15 минут..."
            local _script
            _script="${SCRIPT_PATH:-/usr/local/bin/naiveproxy.sh}"
            if [[ ! -f "${_script}" ]]; then
                tg_reply "${chat_id}" "❌ Скрипт не найден: ${_script}"
                return
            fi
            if bash "${_script}" update >/dev/null 2>&1; then
                tg_reply "${chat_id}" "✅ Caddy обновлён"
            else
                tg_reply "${chat_id}" "❌ Ошибка обновления Caddy"
            fi
            ;;

        /selfupdate)
            tg_reply "${chat_id}" "⬆️ Проверяю обновления скрипта..."
            local latest_ver
            latest_ver=$(curl -s --max-time 8 "${GITHUB_RAW}" 2>/dev/null                 | grep '^VERSION=' | grep -oP '"\K[^"]+' || echo "")
            if [[ -z "${latest_ver}" ]]; then
                tg_reply "${chat_id}" "❌ Не удалось проверить обновления"
            elif [[ "${latest_ver}" == "${VERSION}" ]]; then
                tg_reply "${chat_id}" "✅ Скрипт актуален: v${VERSION}"
            else
                tg_reply "${chat_id}" "⬆️ Доступно обновление v${VERSION} → v${latest_ver}
Запусти на сервере: sudo bash naiveproxy.sh self-update"
            fi
            ;;

        /admins)
            local admin_list="• Главный: <code>${TG_CHAT_ID}</code>"
            if [[ -n "${TG_ADMINS:-}" ]]; then
                local IFS=','
                for aid in ${TG_ADMINS}; do
                    aid="${aid// /}"
                    admin_list+="
• <code>${aid}</code>"
                done
            fi
            tg_reply "${chat_id}" "👮 <b>Администраторы:</b>
${admin_list}"
            ;;

        /addadmin)
            local new_admin="${args%% *}"
            # Защита: только числа, разумная длина
            if [[ -z "${new_admin}" || ! "${new_admin}" =~ ^[0-9]{5,15}$ ]]; then
                tg_reply "${chat_id}" "❌ Использование: /addadmin 123456789"
                return
            fi
            if [[ -z "${TG_ADMINS}" ]]; then
                TG_ADMINS="${new_admin}"
            else
                TG_ADMINS="${TG_ADMINS},${new_admin}"
            fi
            save_config
            tg_reply "${chat_id}" "✅ Администратор <code>${new_admin}</code> добавлен"
            ;;

        /deladmin)
            local del_admin="${args%% *}"
            if [[ -z "${del_admin}" ]]; then
                tg_reply "${chat_id}" "❌ Использование: /deladmin 123456789"
                return
            fi
            TG_ADMINS=$(echo "${TG_ADMINS}" | tr ',' '
'                 | grep -v "^${del_admin}$" | tr '
' ',' | sed 's/,$//')
            save_config
            tg_reply "${chat_id}" "🗑 Администратор <code>${del_admin}</code> удалён"
            ;;

        *)
            tg_reply "${chat_id}" "❓ Неизвестная команда. Используй /help"
            ;;
    esac
}

# Основной цикл бота (long polling)
cmd_bot() {
    [[ -z "${TG_TOKEN:-}" ]] && err "Telegram не настроен. Запусти: sudo bash naiveproxy.sh" && return 1

    info "Запускаю Telegram бот..."
    info "Бот работает. Напиши /help в Telegram."
    info "Для остановки: Ctrl+C"
    echo

    local offset=0

    while true; do
        # Получаем обновления
        local response
        response=$(curl -s --max-time 35             "https://api.telegram.org/bot${TG_TOKEN}/getUpdates?offset=${offset}&timeout=30&allowed_updates=message"             2>/dev/null || echo "")

        if [[ -z "${response}" ]]; then
            sleep 5
            continue
        fi

        # Парсим обновления через python3
        local updates
        updates=$(echo "${response}" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if not data.get('ok'): sys.exit(0)
    for u in data.get('result', []):
        uid = u.get('update_id', 0)
        msg = u.get('message', {})
        chat_id = msg.get('chat', {}).get('id', '')
        from_id = msg.get('from', {}).get('id', '')
        text = msg.get('text', '')
        if text.startswith('/'):
            print(f'{uid}|{chat_id}|{from_id}|{text}')
except: pass
" 2>/dev/null || echo "")

        while IFS='|' read -r update_id chat_id from_id text; do
            [[ -z "${update_id}" ]] && continue
            # Защита от переполнения
            if [[ "${update_id}" =~ ^[0-9]+$ ]] && [[ ${update_id} -lt 2147483647 ]]; then
                offset=$(( update_id + 1 ))
            fi
            tg_handle_command "${chat_id}" "${from_id}" "${text}"
        done <<< "${updates}"

        sleep 1
    done
}

# Запуск бота как systemd сервиса
install_bot_service() {
    local script_path="${SCRIPT_PATH:-/usr/local/bin/naiveproxy.sh}"

    cat > /etc/systemd/system/naiveproxy-bot.service << EOF
[Unit]
Description=NaiveProxy Telegram Bot
After=network-online.target caddy.service
Wants=network-online.target

[Service]
Type=simple
ExecStart=/bin/bash ${script_path} bot
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable naiveproxy-bot --quiet
    systemctl restart naiveproxy-bot
    ok "Telegram бот установлен как системный сервис"
    ok "Статус: systemctl status naiveproxy-bot"
}

# Обёртка tg_send_stats_to для отправки конкретному chat_id
tg_send_stats_to() {
    local target_chat="$1"
    local caddy_ver
    caddy_ver=$(/usr/local/bin/caddy version 2>/dev/null | head -1 | awk '{print $1}' || echo "н/д")

    local caddy_status="🔴 Остановлен"
    systemctl is-active caddy &>/dev/null && caddy_status="🟢 Работает"

    local cert_days="н/д"
    if [[ -n "${DOMAIN:-}" ]]; then
        local not_after expire_ts
        not_after=$(echo | timeout 5 openssl s_client             -connect "${DOMAIN}:443" -servername "${DOMAIN}" 2>/dev/null             | openssl x509 -noout -dates 2>/dev/null             | grep "notAfter" | cut -d= -f2 || echo "")
        if [[ -n "${not_after}" ]]; then
            expire_ts=$(date -d "${not_after}" +%s 2>/dev/null || echo 0)
            cert_days=$(( (expire_ts - $(date +%s)) / 86400 ))
        fi
    fi

    tg_reply "${target_chat}" "📊 <b>Статистика NaiveProxy</b>

🌐 Домен: <code>${DOMAIN:-н/д}</code>
📡 Статус: ${caddy_status}
📦 Caddy: <code>${caddy_ver}</code>
👥 Пользователей: $(get_users | wc -l)

🖥 Сервер: <code>$(hostname)</code>
💾 RAM: $(free -h | awk '/Mem:/{print $3"/"$2}')
💿 Диск: $(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')
⚡ CPU: $(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')

🔐 Сертификат: ${cert_days} дней
🕐 $(date '+%Y-%m-%d %H:%M:%S')"
}


# ══════════════════════════════════════════════════════════════
#   DNS БЛОКИРОВКА РЕКЛАМЫ (unbound + blocklists)
# ══════════════════════════════════════════════════════════════

DNS_CONF="/etc/unbound/unbound.conf.d/naiveproxy-dns.conf"
DNS_BLOCKLIST="/etc/unbound/blocklist.conf"
DNS_WHITELIST="/etc/unbound/whitelist.txt"
DNS_STATS_FILE="/etc/naiveproxy/dns_stats"

# Источники blocklists (совместимы с unbound)
BLOCKLIST_SOURCES=(
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
    "https://adaway.org/hosts.txt"
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.txt"
)

cmd_dns_install() {
    hr
    echo -e "${BOLD}  🚫 Установка DNS блокировщика рекламы${RESET}"
    hr

    # Устанавливаем unbound
    info "Устанавливаю unbound..."
    apt-get install -y -q unbound unbound-anchor curl

    # Настраиваем unbound как рекурсивный DNS резолвер
    info "Настраиваю unbound..."
    cat > "${DNS_CONF}" << 'UNBOUNDEOF'
server:
    # Слушаем только локально
    interface: 127.0.0.1
    port: 5335
    do-ip4: yes
    do-ip6: no
    do-udp: yes
    do-tcp: yes

    # Безопасность
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: yes
    harden-large-queries: yes
    harden-short-bufsize: yes

    # Производительность
    prefetch: yes
    prefetch-key: yes
    num-threads: 2
    so-rcvbuf: 1m
    msg-cache-size: 50m
    rrset-cache-size: 100m
    cache-min-ttl: 3600
    cache-max-ttl: 86400

    # Логи для статистики
    log-queries: no
    statistics-interval: 0

    # Подключаем blocklist
    include: /etc/unbound/blocklist.conf

    # Upstream DNS (Cloudflare + Google через DoT)
    forward-zone:
        name: "."
        forward-addr: 1.1.1.1@853#cloudflare-dns.com
        forward-addr: 1.0.0.1@853#cloudflare-dns.com
        forward-addr: 8.8.8.8@853#dns.google
        forward-tls-upstream: yes
UNBOUNDEOF

    # Создаём пустой blocklist если нет
    [[ -f "${DNS_BLOCKLIST}" ]] || touch "${DNS_BLOCKLIST}"

    # Проверяем конфиг
    if ! unbound-checkconf "${DNS_CONF}" &>/dev/null; then
        err "Ошибка конфига unbound!"
        return 1
    fi

    # Запускаем unbound
    systemctl enable unbound --quiet
    systemctl restart unbound
    sleep 2

    if ! systemctl is-active unbound &>/dev/null; then
        err "unbound не запустился!"
        journalctl -u unbound -n 10 --no-pager
        return 1
    fi

    ok "unbound запущен на 127.0.0.1:5335"

    # Обновляем blocklists
    cmd_dns_update

    # Интегрируем с Caddyfile — добавляем DNS
    _dns_integrate_caddy

    # Статистика
    mkdir -p "$(dirname "${DNS_STATS_FILE}")"
    echo "0" > "${DNS_STATS_FILE}"

    ok "DNS блокировщик установлен!"
    tg_send "🚫 <b>DNS блокировщик установлен</b>
🖥 Сервер: <code>$(hostname)</code>
🔒 Режим: unbound + blocklists
🕐 $(date '+%Y-%m-%d %H:%M:%S')"
}

# Интеграция с Caddy — передаём DNS через unbound
_dns_integrate_caddy() {
    # Добавляем локальный DNS резолвер в системный
    if ! grep -q "127.0.0.1" /etc/resolv.conf; then
        # Бэкап
        cp /etc/resolv.conf /etc/resolv.conf.bak 2>/dev/null || true
        echo "nameserver 127.0.0.1" > /tmp/resolv_new
        echo "nameserver 1.1.1.1" >> /tmp/resolv_new
        cat /etc/resolv.conf >> /tmp/resolv_new
        cp /tmp/resolv_new /etc/resolv.conf
        ok "DNS: добавлен 127.0.0.1 в /etc/resolv.conf"
    fi
}

# Обновление blocklists
cmd_dns_update() {
    hr
    echo -e "${BOLD}  🔄 Обновление DNS blocklists${RESET}"
    hr

    if ! command -v unbound &>/dev/null; then
        err "unbound не установлен. Сначала: меню → DNS блокировщик → Установить"
        return 1
    fi

    info "Скачиваю blocklists..."
    local tmp_hosts
    tmp_hosts=$(mktemp)
    trap 'rm -f "${tmp_hosts}" 2>/dev/null' RETURN

    local total=0
    local blocked=0

    for url in "${BLOCKLIST_SOURCES[@]}"; do
        info "  → ${url##*/}"
        if curl -fsSL --max-time 30 "${url}" >> "${tmp_hosts}" 2>/dev/null; then
            ok "  Загружено"
        else
            warn "  Не удалось загрузить"
        fi
    done

    # Парсим hosts формат и конвертируем в unbound
    info "Конвертирую в формат unbound..."

    # Читаем whitelist
    local whitelist_domains=""
    if [[ -f "${DNS_WHITELIST}" ]]; then
        whitelist_domains=$(grep -v '^#' "${DNS_WHITELIST}" | tr '
' '|' | sed 's/|$//')
    fi

    python3 << PYEOF2
import sys

hosts_file = "${tmp_hosts}"
output_file = "${DNS_BLOCKLIST}"
whitelist = "${whitelist_domains}"
wl_set = set(whitelist.split('|')) if whitelist else set()

blocked = 0
seen = set()

with open(hosts_file, 'r', encoding='utf-8', errors='ignore') as f,      open(output_file, 'w') as out:
    out.write("# NaiveProxy DNS Blocklist — обновлено $(date '+%Y-%m-%d %H:%M:%S')
")
    for line in f:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        parts = line.split()
        if len(parts) >= 2 and parts[0] in ('0.0.0.0', '127.0.0.1'):
            domain = parts[1].lower().strip()
            # Фильтруем мусор
            if domain in ('localhost', '0.0.0.0', '127.0.0.1', '::1', 'local'):
                continue
            if '.' not in domain:
                continue
            if domain in seen:
                continue
            if domain in wl_set:
                continue
            seen.add(domain)
            out.write(f'local-zone: "{domain}" refuse
')
            blocked += 1

print(f"blocked={blocked}")
PYEOF2

    # Считаем заблокированных
    blocked=$(grep -c "^local-zone" "${DNS_BLOCKLIST}" 2>/dev/null || echo 0)

    # Перезапускаем unbound
    if unbound-checkconf "${DNS_CONF}" &>/dev/null; then
        systemctl restart unbound
        ok "unbound перезапущен"
    else
        err "Ошибка в blocklist — откат"
        echo "" > "${DNS_BLOCKLIST}"
        systemctl restart unbound
        return 1
    fi

    # Сохраняем статистику
    echo "${blocked}" > "${DNS_STATS_FILE}"

    ok "Blocklist обновлён: ${blocked} доменов заблокировано"
    info "Последнее обновление: $(date '+%Y-%m-%d %H:%M:%S')"

    tg_send "🚫 <b>DNS Blocklist обновлён</b>
🔒 Заблокировано доменов: <b>${blocked}</b>
🕐 $(date '+%Y-%m-%d %H:%M:%S')"
}

# Статус DNS блокировщика
cmd_dns_status() {
    hr
    echo -e "${BOLD}  🚫 DNS Блокировщик${RESET}"
    hr

    if ! command -v unbound &>/dev/null; then
        warn "unbound не установлен"
        return
    fi

    if systemctl is-active unbound &>/dev/null; then
        ok "unbound: запущен"
    else
        err "unbound: остановлен"
    fi

    local blocked=0
    [[ -f "${DNS_STATS_FILE}" ]] && blocked=$(cat "${DNS_STATS_FILE}")
    [[ -f "${DNS_BLOCKLIST}" ]] && blocked=$(grep -c "^local-zone" "${DNS_BLOCKLIST}" 2>/dev/null || echo 0)

    echo -e "  Заблокировано доменов: ${CYAN}${blocked}${RESET}"

    # Тест блокировки
    echo
    info "Тест блокировки рекламных доменов..."
    local test_domains=("ads.google.com" "tracking.google.com" "doubleclick.net" "googlesyndication.com")
    for domain in "${test_domains[@]}"; do
        if dig "@127.0.0.1" -p 5335 "${domain}" +short 2>/dev/null | grep -q "REFUSED\|^$"; then
            echo -e "  ${GREEN}✅ ${domain} — ЗАБЛОКИРОВАН${RESET}"
        else
            echo -e "  ${YELLOW}⚠️  ${domain} — не заблокирован${RESET}"
        fi
    done

    echo
    info "Тест пропуска нормальных доменов..."
    local ok_domains=("google.com" "youtube.com" "github.com")
    for domain in "${ok_domains[@]}"; do
        local result
        result=$(dig "@127.0.0.1" -p 5335 "${domain}" +short 2>/dev/null | head -1)
        if [[ -n "${result}" ]]; then
            echo -e "  ${GREEN}✅ ${domain} → ${result}${RESET}"
        else
            echo -e "  ${RED}❌ ${domain} — не резолвится!${RESET}"
        fi
    done
    hr
}

# Добавить домен в whitelist (разрешить)
cmd_dns_whitelist() {
    hr
    echo -e "${BOLD}  ✅ Whitelist (разрешить домен)${RESET}"
    hr

    echo -ne "${CYAN}Домен для разрешения: ${RESET}"
    read -r wl_domain
    if [[ -z "${wl_domain}" ]]; then
        warn "Домен не указан"
        return
    fi

    # Убираем из blocklist
    if grep -q ""${wl_domain}"" "${DNS_BLOCKLIST}" 2>/dev/null; then
        grep -v ""${wl_domain}"" "${DNS_BLOCKLIST}" > "${DNS_BLOCKLIST}.tmp"             && mv "${DNS_BLOCKLIST}.tmp" "${DNS_BLOCKLIST}"
        ok "${wl_domain} удалён из blocklist"
    fi

    # Добавляем в whitelist файл
    echo "${wl_domain}" >> "${DNS_WHITELIST}"
    ok "${wl_domain} добавлен в whitelist"

    systemctl restart unbound
    ok "unbound перезапущен"
}

# Удалить DNS блокировщик
cmd_dns_remove() {
    echo -ne "${YELLOW}Удалить DNS блокировщик? [y/N]: ${RESET}"
    read -r ans
    [[ "${ans,,}" != "y" ]] && return

    systemctl stop unbound 2>/dev/null || true
    systemctl disable unbound 2>/dev/null || true
    rm -f "${DNS_CONF}" "${DNS_BLOCKLIST}" "${DNS_WHITELIST}"

    # Восстанавливаем resolv.conf
    [[ -f /etc/resolv.conf.bak ]] && cp /etc/resolv.conf.bak /etc/resolv.conf

    ok "DNS блокировщик удалён"
}

# Меню DNS блокировщика
cmd_dns_menu() {
    while true; do
        hr
        echo -e "${BOLD}  🚫 DNS Блокировщик рекламы${RESET}"
        hr

        local blocked=0
        [[ -f "${DNS_BLOCKLIST}" ]] && blocked=$(grep -c "^local-zone" "${DNS_BLOCKLIST}" 2>/dev/null || echo 0)
        local dns_status="${RED}не установлен${RESET}"
        command -v unbound &>/dev/null && systemctl is-active unbound &>/dev/null             && dns_status="${GREEN}активен (${blocked} доменов)${RESET}"

        echo -e "  Статус: ${dns_status}"
        echo
        echo -e "  ${BOLD}1)${RESET} Установить блокировщик"
        echo -e "  ${BOLD}2)${RESET} Обновить blocklists"
        echo -e "  ${BOLD}3)${RESET} Статус и тест"
        echo -e "  ${BOLD}4)${RESET} Разрешить домен (whitelist)"
        echo -e "  ${BOLD}5)${RESET} Удалить блокировщик"
        echo -e "  ${BOLD}0)${RESET} Назад"
        hr
        echo -ne "${CYAN}Выбор: ${RESET}"
        read -r choice

        case "${choice}" in
            1) cmd_dns_install ;;
            2) cmd_dns_update ;;
            3) cmd_dns_status ;;
            4) cmd_dns_whitelist ;;
            5) cmd_dns_remove ;;
            0) break ;;
            *) warn "Неверный выбор" ;;
        esac

        echo -ne "${YELLOW}Enter для продолжения...${RESET}"; read -r
    done
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
    [[ -n "${CONFIG_DIR:-}" && "$CONFIG_DIR" != "/" ]] && rm -rf "$CONFIG_DIR"
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
    echo -e "${BOLD}${CYAN}   NaiveProxy Manager v${VERSION}${RESET}  ${DIM}[$(t "РУС" "ENG")]${RESET}"
    echo -e "   Статус: ${status_str}  |  Домен: ${CYAN}${DOMAIN:-не задан}${RESET}"
    local ssh_str="${YELLOW}не настроен${RESET}"
    [[ -f "$SSH_HARDENING_DONE" ]] && ssh_str="${GREEN}$(grep SSH_PORT "$SSH_HARDENING_DONE" 2>/dev/null | cut -d= -f2)${RESET}"
    echo -e "   Telegram: ${tg_str}  |  Юзеров: $(get_users | wc -l)  |  SSH порт: ${ssh_str}"
    hr
    echo -e "   ${BOLD}1)${RESET}  Установить NaiveProxy"
    echo -e "   ${BOLD}2)${RESET}  Статус"
    echo -e "   ${BOLD}3)${RESET}  Клиентский конфиг"
    echo -e "   ${BOLD}4)${RESET}  Управление пользователями"
    echo -e "   ${BOLD}5)${RESET}  🌐 Управление доменами"
    echo -e "   ${BOLD}6)${RESET}  Мониторинг и статистика"
    echo -e "   ${BOLD}7)${RESET}  Настройка Telegram + Бот"
    echo -e "   ${BOLD}8)${RESET}  Перезапустить Caddy"
    echo -e "   ${BOLD}9)${RESET}  Обновить Caddy"
    echo -e "   ${BOLD}10)${RESET} Логи"
    echo -e "   ${BOLD}11)${RESET} Удалить NaiveProxy"
    echo -e "   ${BOLD}16)${RESET} 🔍 Диагностика системы"
    echo -e "   ${BOLD}17)${RESET} 🚫 DNS блокировщик рекламы"
    echo -e "   ──────────────────────────"
    echo -e "   ${BOLD}12)${RESET} 🔒 SSH Hardening"
    echo -e "   ${BOLD}13)${RESET} 🔄 Обновить систему"
    echo -e "   ${BOLD}14)${RESET} ⬆️  Обновить скрипт
   ${BOLD}15)${RESET} 🎭 Обновить камуфляж"
    echo -e "   ${BOLD}0)${RESET}  Выход"
    hr
    echo -ne "${CYAN}Выбор [0-15]: ${RESET}"
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
            cert)        load_config; check_cert "${DOMAIN:-}" ;;
            domains)     load_config; cmd_domains ;;
            qr)          load_config; print_client_config ;;
            ssh-key)     cat "${CONFIG_DIR}/ssh_private_key" 2>/dev/null || err "Ключ не найден: ${CONFIG_DIR}/ssh_private_key" ;;
            diagnose)    cmd_diagnose ;;
            dns)         cmd_dns_menu ;;
            dns-install) cmd_dns_install ;;
            dns-update)  cmd_dns_update ;;
            dns-status)  cmd_dns_status ;;
            bot)         load_config; cmd_bot ;;
            bot-install) load_config; install_bot_service ;;
            self-update)  load_config; cmd_self_update ;;
            camouflage)   install_camouflage_page ;;
            version)
                echo "NaiveProxy Manager v${VERSION}"
                echo "Telegram: https://t.me/+XVSkY6blCTY0ZDU6"
                echo "Сайт:     https://ivan-it.net"
                echo "GitHub:   github.com/ivanstudiya-cpu/naiveproxy"
                ;;
            *) err "Неизвестная команда: $1"
               echo "Доступные: install status config restart update remove logs monitor users tg-stats ssh-hardening sysupdate cert domains self-update version camouflage"
               exit 1 ;;
        esac
        exit 0
    fi

    # Тихая проверка обновлений в фоне
    check_update_available

    while true; do
        show_menu
        read -r choice; echo
        load_config; load_users
        case "$choice" in
            1)  cmd_install ;;
            2)  cmd_status ;;
            3)  print_client_config ;;
            4)  cmd_users ;;
            5)  cmd_domains ;;
            6)  cmd_monitor ;;
            7)  setup_telegram ;;
            8)  cmd_restart ;;
            9)  cmd_update ;;
            10) cmd_logs ;;
            11) cmd_remove ;;
            12) cmd_ssh_hardening ;;
            13) cmd_sysupdate ;;
            14) cmd_self_update ;;
            15) install_camouflage_page && ok "Камуфляж обновлён" ;;
            16) cmd_diagnose ;;
            17) cmd_dns_menu ;;
            0)  echo -e "${GREEN}Пока!${RESET}"; exit 0 ;;
            *)  warn "Неверный выбор" ;;
        esac
        echo
        echo -ne "${YELLOW}Нажми Enter чтобы вернуться в меню...${RESET}"
        read -r
    done
}

main "$@"
