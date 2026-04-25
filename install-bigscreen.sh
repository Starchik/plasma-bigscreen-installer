#!/bin/bash
# ╔══════════════════════════════════════════════════╗
# ║   Plasma Bigscreen Auto-Installer               ║
# ║   Ubuntu Server 22.04 / 24.04 LTS              ║
# ║   Запускать на уже установленном Ubuntu Server  ║
# ╚══════════════════════════════════════════════════╝

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

step()  { echo -e "\n${BLUE}${BOLD}[▶] $1${NC}"; }
ok()    { echo -e "${GREEN}✔ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠  $1${NC}"; }
die()   { echo -e "${RED}✘ ОШИБКА: $1${NC}"; exit 1; }
info()  { echo -e "${CYAN}ℹ  $1${NC}"; }

[[ $EUID -ne 0 ]] && die "Запусти скрипт через: sudo bash install-bigscreen.sh"

if ! grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
    die "Этот скрипт только для Ubuntu."
fi

UBUNTU_VER=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2)
info "Обнаружена Ubuntu $UBUNTU_VER"
if [[ "$UBUNTU_VER" != "22.04" && "$UBUNTU_VER" != "24.04" ]]; then
    warn "Скрипт тестировался на 22.04 и 24.04. Версия $UBUNTU_VER может работать нестабильно."
    read -rp "Продолжить всё равно? [y/N]: " _c
    [[ "$_c" != "y" && "$_c" != "Y" ]] && die "Установка отменена."
fi

clear
echo -e "${CYAN}${BOLD}"
cat << 'BANNER'
 ██████╗ ██╗ ██████╗ ███████╗ ██████╗ ██████╗ ███████╗███████╗███╗   ██╗
 ██╔══██╗██║██╔════╝ ██╔════╝██╔════╝██╔══██╗██╔════╝██╔════╝████╗  ██║
 ██████╔╝██║██║  ███╗███████╗██║     ██████╔╝█████╗  █████╗  ██╔██╗ ██║
 ██╔══██╗██║██║   ██║╚════██║██║     ██╔══██╗██╔══╝  ██╔══╝  ██║╚██╗██║
 ██████╔╝██║╚██████╔╝███████║╚██████╗██║  ██║███████╗███████╗██║ ╚████║
 ╚═════╝ ╚═╝ ╚═════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝
        Plasma Bigscreen Auto-Installer для Ubuntu Server
BANNER
echo -e "${NC}"

# ── Сбор данных ──────────────────────────────────
step "Настройка установки"

DEFAULT_USER=$(logname 2>/dev/null || who am i | awk '{print $1}' || echo "")

if [[ -n "$DEFAULT_USER" && "$DEFAULT_USER" != "root" ]]; then
    info "Обнаружен пользователь: $DEFAULT_USER"
    read -rp "$(echo -e "${BOLD}Использовать '$DEFAULT_USER' для автологина? [Y/n]: ${NC}")" _use
    if [[ "$_use" == "n" || "$_use" == "N" ]]; then
        read -rp "$(echo -e "${BOLD}Введи имя пользователя: ${NC}")" BIGSCREEN_USER
    else
        BIGSCREEN_USER="$DEFAULT_USER"
    fi
else
    read -rp "$(echo -e "${BOLD}Введи имя пользователя для автологина: ${NC}")" BIGSCREEN_USER
fi

if ! id "$BIGSCREEN_USER" &>/dev/null; then
    warn "Пользователь '$BIGSCREEN_USER' не найден. Создать? [Y/n]"
    read -rp "" _create
    if [[ "$_create" != "n" && "$_create" != "N" ]]; then
        useradd -m -s /bin/bash "$BIGSCREEN_USER"
        info "Установи пароль для $BIGSCREEN_USER:"
        passwd "$BIGSCREEN_USER"
        usermod -aG sudo,audio,video,input "$BIGSCREEN_USER"
        ok "Пользователь $BIGSCREEN_USER создан"
    else
        die "Пользователь не найден. Установка отменена."
    fi
fi

USER_HOME=$(getent passwd "$BIGSCREEN_USER" | cut -d: -f6)

echo ""
echo -e "${YELLOW}${BOLD}════════════════════════════════════════════"
echo "  Будет установлено:"
echo "  • KDE Plasma Desktop + SDDM"
echo "  • PipeWire (звук)"
echo "  • Plasma Bigscreen (сборка из исходников)"
echo "  • Flatpak + Flathub"
echo "  Пользователь автологина: $BIGSCREEN_USER"
echo "════════════════════════════════════════════${NC}"
echo ""
read -rp "$(echo -e "${BOLD}Продолжить? [Y/n]: ${NC}")" _go
[[ "$_go" == "n" || "$_go" == "N" ]] && die "Установка отменена."

# ── Шаг 1: Обновление ────────────────────────────
step "Обновление системы..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
ok "Готово"

# ── Шаг 2: KDE Plasma + SDDM ─────────────────────
step "Установка KDE Plasma и SDDM (~10 мин)..."
apt-get install -y -qq \
    kde-plasma-desktop sddm \
    plasma-workspace \
    kwin-wayland kwin-x11
ok "KDE Plasma установлен"

# ── Шаг 3: Звук ──────────────────────────────────
step "Установка PipeWire..."
apt-get install -y -qq \
    pipewire pipewire-pulse pipewire-alsa wireplumber
ok "PipeWire установлен"

# ── Шаг 4: Зависимости сборки ─────────────────────
step "Установка зависимостей для сборки..."
apt-get install -y -qq \
    git cmake make ninja-build build-essential \
    extra-cmake-modules \
    qt6-base-dev qt6-declarative-dev qt6-wayland-dev \
    libkf6plasma-dev libkf6i18n-dev libkf6config-dev \
    libkf6coreaddons-dev libkf6windowsystem-dev \
    libkf6notifications-dev libkf6dbusaddons-dev \
    libkf6service-dev libkf6activities-dev \
    flatpak
ok "Зависимости установлены"

# ── Шаг 5: Клонирование и сборка Bigscreen ────────
step "Сборка Plasma Bigscreen из исходников (20–40 мин)..."

BUILD_DIR="$USER_HOME/kde-src"
mkdir -p "$BUILD_DIR"
chown "$BIGSCREEN_USER:$BIGSCREEN_USER" "$BUILD_DIR"

BIGSCREEN_SRC="$BUILD_DIR/plasma-bigscreen"
if [[ -d "$BIGSCREEN_SRC" ]]; then
    info "Исходники уже есть, обновляем..."
    git -C "$BIGSCREEN_SRC" pull --ff-only > /dev/null 2>&1 || true
else
    git clone https://invent.kde.org/plasma/plasma-bigscreen.git \
        "$BIGSCREEN_SRC" > /dev/null 2>&1
fi

BUILD_TMP="$BUILD_DIR/plasma-bigscreen-build"
mkdir -p "$BUILD_TMP"

cmake -S "$BIGSCREEN_SRC" -B "$BUILD_TMP" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -G Ninja \
    > /dev/null 2>&1

ninja -C "$BUILD_TMP" -j"$(nproc)" > /dev/null 2>&1
ninja -C "$BUILD_TMP" install > /dev/null 2>&1

chown -R "$BIGSCREEN_USER:$BIGSCREEN_USER" "$BUILD_DIR"
ok "Plasma Bigscreen собран и установлен"

# ── Шаг 6: Wayland-сессия ─────────────────────────
step "Регистрация Wayland-сессии..."
mkdir -p /usr/share/wayland-sessions

cat > /usr/share/wayland-sessions/plasma-bigscreen-wayland.desktop << 'SESSION'
[Desktop Entry]
Name=Plasma Bigscreen
Comment=KDE Plasma Bigscreen (Wayland)
Exec=/usr/local/bin/startplasma-bigscreen-wayland
TryExec=/usr/local/bin/startplasma-bigscreen-wayland
Type=Application
DesktopNames=KDE
X-KDE-SessionType=wayland
SESSION

if [[ ! -f "/usr/local/bin/startplasma-bigscreen-wayland" ]]; then
    cat > "/usr/local/bin/startplasma-bigscreen-wayland" << 'STARTSESSION'
#!/bin/bash
export QT_QUICK_CONTROLS_STYLE=org.kde.breeze
export QT_ENABLE_GLYPH_CACHE_WORKAROUND=1
export QT_QUICK_CONTROLS_MOBILE=true
export PLASMA_INTEGRATION_USE_PORTAL=1
export PLASMA_PLATFORM=mediacenter
export QT_FILE_SELECTORS=mediacenter
export PLASMA_DEFAULT_SHELL=org.kde.plasma.bigscreen
dbus-run-session kwin_wayland "plasmashell -p org.kde.plasma.bigscreen"
STARTSESSION
    chmod +x "/usr/local/bin/startplasma-bigscreen-wayland"
fi
ok "Сессия зарегистрирована"

# ── Шаг 7: SDDM автологин ─────────────────────────
step "Настройка SDDM и автологина..."
mkdir -p /etc/sddm.conf.d

cat > /etc/sddm.conf.d/autologin.conf << SDDM
[Autologin]
User=$BIGSCREEN_USER
Session=plasma-bigscreen-wayland

[Theme]
Current=breeze
SDDM

systemctl disable gdm gdm3 lightdm 2>/dev/null || true
systemctl enable sddm
ok "SDDM настроен, автологин → $BIGSCREEN_USER"

# ── Шаг 8: Flathub ────────────────────────────────
step "Подключение Flathub..."
sudo -u "$BIGSCREEN_USER" flatpak remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
ok "Flathub подключён"

# ── Шаг 9: PipeWire автозапуск ────────────────────
step "Настройка автозапуска звука..."
AUTOSTART_DIR="$USER_HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

cat > "$AUTOSTART_DIR/pipewire.desktop" << 'PW'
[Desktop Entry]
Type=Application
Name=PipeWire
Exec=pipewire
NoDisplay=true
X-GNOME-Autostart-enabled=true
PW

cat > "$AUTOSTART_DIR/wireplumber.desktop" << 'WP'
[Desktop Entry]
Type=Application
Name=WirePlumber
Exec=wireplumber
NoDisplay=true
X-GNOME-Autostart-enabled=true
WP

chown -R "$BIGSCREEN_USER:$BIGSCREEN_USER" "$USER_HOME/.config"
ok "Автозапуск PipeWire настроен"

# ── Готово ─────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ Plasma Bigscreen установлен!                            ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  Перезагрузи систему:  sudo reboot                          ║"
echo "║                                                              ║"
echo "║  После перезагрузки система автоматически войдёт            ║"
echo "║  в Plasma Bigscreen.                                         ║"
echo "║                                                              ║"
echo "║  Популярные приложения:                                      ║"
echo "║  • Kodi:     sudo apt install kodi                           ║"
echo "║  • Jellyfin: flatpak install flathub                         ║"
echo "║              com.github.iwalton3.jellyfin-media-player       ║"
echo "║  • YouTube:  flatpak install flathub                         ║"
echo "║              io.github.msaintfelix.VacuumTube                ║"
echo "║                                                              ║"
echo "║  🎮 Enjoy Plasma Bigscreen!                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
