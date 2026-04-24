#!/bin/bash
# ╔══════════════════════════════════════════════════╗
# ║   Plasma Bigscreen Auto-Installer               ║
# ║   Arch Linux → Fujitsu Esprimo / x86_64         ║
# ║   Запускать с Arch Linux Live USB               ║
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

# ── Проверка: запущен ли скрипт от root ───────────
[[ $EUID -ne 0 ]] && die "Запусти скрипт через: sudo bash install-bigscreen.sh"

clear
echo -e "${CYAN}${BOLD}"
cat << 'BANNER'
 ██████╗ ██╗ ██████╗ ███████╗ ██████╗ ██████╗ ███████╗███████╗███╗   ██╗
 ██╔══██╗██║██╔════╝ ██╔════╝██╔════╝██╔══██╗██╔════╝██╔════╝████╗  ██║
 ██████╔╝██║██║  ███╗███████╗██║     ██████╔╝█████╗  █████╗  ██╔██╗ ██║
 ██╔══██╗██║██║   ██║╚════██║██║     ██╔══██╗██╔══╝  ██╔══╝  ██║╚██╗██║
 ██████╔╝██║╚██████╔╝███████║╚██████╗██║  ██║███████╗███████╗██║ ╚████║
 ╚═════╝ ╚═╝ ╚═════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝
          Plasma Bigscreen Auto-Installer для Fujitsu Esprimo
BANNER
echo -e "${NC}"

# ══════════════════════════════════════════════════
# ШАГ 1: Сбор данных
# ══════════════════════════════════════════════════
step "Доступные диски:"
lsblk -d -o NAME,SIZE,MODEL --noheadings | grep -v "loop"
echo ""

while true; do
    read -rp "$(echo -e "${BOLD}Введи имя диска для установки (например sda или nvme0n1): ${NC}")" DISK_NAME
    DISK="/dev/$DISK_NAME"
    [[ -b "$DISK" ]] && break
    warn "Диск $DISK не найден, попробуй снова."
done

echo ""
while true; do
    read -rp "$(echo -e "${BOLD}Имя пользователя (латиница, строчные): ${NC}")" USERNAME
    [[ "$USERNAME" =~ ^[a-z][a-z0-9_-]{1,31}$ ]] && break
    warn "Недопустимое имя. Только строчные латинские буквы и цифры."
done

echo ""
while true; do
    read -rsp "$(echo -e "${BOLD}Пароль для $USERNAME: ${NC}")" USER_PASS; echo
    read -rsp "$(echo -e "${BOLD}Повтори пароль: ${NC}")" USER_PASS2; echo
    [[ "$USER_PASS" == "$USER_PASS2" ]] && break
    warn "Пароли не совпадают, попробуй снова."
done

echo ""
while true; do
    read -rsp "$(echo -e "${BOLD}Пароль root: ${NC}")" ROOT_PASS; echo
    read -rsp "$(echo -e "${BOLD}Повтори пароль root: ${NC}")" ROOT_PASS2; echo
    [[ "$ROOT_PASS" == "$ROOT_PASS2" ]] && break
    warn "Пароли не совпадают, попробуй снова."
done

echo ""
read -rp "$(echo -e "${BOLD}Имя компьютера [bigscreen]: ${NC}")" HOSTNAME
HOSTNAME="${HOSTNAME:-bigscreen}"

# ── Подтверждение ─────────────────────────────────
echo ""
echo -e "${YELLOW}${BOLD}══════════════════════════════════════════"
echo "  ВНИМАНИЕ: ВСЕ ДАННЫЕ НА $DISK БУДУТ УДАЛЕНЫ!"
echo "══════════════════════════════════════════${NC}"
echo ""
echo -e "  Диск:        ${BOLD}$DISK${NC}"
echo -e "  Пользователь: ${BOLD}$USERNAME${NC}"
echo -e "  Hostname:    ${BOLD}$HOSTNAME${NC}"
echo ""
read -rp "$(echo -e "${BOLD}Продолжить? Введи ${RED}YES${NC}${BOLD} для подтверждения: ${NC}")" CONFIRM
[[ "$CONFIRM" != "YES" ]] && die "Установка отменена."

# ══════════════════════════════════════════════════
# ШАГ 2: Разметка диска
# ══════════════════════════════════════════════════
step "Разметка и форматирование диска $DISK..."

# Определяем префикс раздела (sda→sda1, nvme0n1→nvme0n1p1)
if [[ "$DISK_NAME" == nvme* ]]; then
    PART1="${DISK}p1"
    PART2="${DISK}p2"
else
    PART1="${DISK}1"
    PART2="${DISK}2"
fi

sgdisk --zap-all "$DISK" > /dev/null 2>&1
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI"   "$DISK" > /dev/null
sgdisk -n 2:0:0     -t 2:8300 -c 2:"Linux" "$DISK" > /dev/null
partprobe "$DISK"
sleep 2

mkfs.fat -F32 "$PART1" > /dev/null
mkfs.ext4 -F  "$PART2" > /dev/null
ok "Диск размечен: $PART1 (EFI, 512МБ) + $PART2 (Linux, остальное)"

# ══════════════════════════════════════════════════
# ШАГ 3: Монтирование
# ══════════════════════════════════════════════════
step "Монтирование разделов..."
mount "$PART2" /mnt
mkdir -p /mnt/boot
mount "$PART1" /mnt/boot
ok "Разделы смонтированы"

# ══════════════════════════════════════════════════
# ШАГ 4: Базовая система
# ══════════════════════════════════════════════════
step "Установка базовой системы Arch Linux (5–15 минут)..."
pacstrap -K /mnt \
    base linux linux-firmware \
    networkmanager sudo nano git base-devel \
    plasma-desktop sddm \
    pipewire pipewire-pulse pipewire-alsa wireplumber \
    xorg-server flatpak \
    grub efibootmgr \
    2>&1 | tail -5
ok "Базовая система установлена"

# ══════════════════════════════════════════════════
# ШАГ 5: fstab
# ══════════════════════════════════════════════════
step "Генерация fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
ok "fstab создан"

# ══════════════════════════════════════════════════
# ШАГ 6: Генерация post-boot скрипта (AUR)
# ══════════════════════════════════════════════════
step "Подготовка скрипта для установки Plasma Bigscreen..."

cat > /mnt/home-bigscreen-install.sh << POSTBOOT
#!/bin/bash
# Этот скрипт запускается ПОСЛЕ первой загрузки, от имени пользователя

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

step()  { echo -e "\n\${BLUE}\${BOLD}[▶] \$1\${NC}"; }
ok()    { echo -e "\${GREEN}✔ \$1\${NC}"; }

echo -e "\${BLUE}\${BOLD}"
echo "══════════════════════════════════════════"
echo "  Этап 2: Установка Plasma Bigscreen"
echo "══════════════════════════════════════════"
echo -e "\${NC}"

# Установка yay
step "Установка yay (AUR-менеджер)..."
cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ~
rm -rf yay
ok "yay установлен"

# Установка Plasma Bigscreen
step "Установка Plasma Bigscreen (сборка из исходников, 15–25 мин)..."
yay -S --noconfirm plasma-bigscreen-git
ok "Plasma Bigscreen установлен"

# Flathub
step "Подключение Flathub..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
ok "Flathub подключён"

# Удаляем скрипт после выполнения
rm -- "\$0"

echo ""
echo -e "\${GREEN}\${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║  ✅ Plasma Bigscreen полностью готов!    ║"
echo "║  Выполни: sudo reboot                    ║"
echo "╚══════════════════════════════════════════╝"
echo -e "\${NC}"
POSTBOOT

ok "Скрипт пост-установки создан"

# ══════════════════════════════════════════════════
# ШАГ 7: Chroot-настройка
# ══════════════════════════════════════════════════
step "Настройка системы внутри chroot..."

arch-chroot /mnt /bin/bash << CHROOT
set -e

# Время
ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime
hwclock --systohc

# Локаль
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen > /dev/null
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
HOSTS

# Пароли
echo "root:$ROOT_PASS" | chpasswd
useradd -m -G wheel,audio,video,input -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASS" | chpasswd

# sudoers
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# Bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB > /dev/null 2>&1
grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1

# Сервисы
systemctl enable NetworkManager > /dev/null 2>&1
systemctl enable sddm > /dev/null 2>&1

# SDDM: автологин (сессия будет доступна после установки bigscreen на шаге 2)
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf << SDDM
[Autologin]
User=$USERNAME
Session=plasma-bigscreen-wayland
SDDM

# Перемещаем скрипт пост-установки в домашнюю папку
mv /home-bigscreen-install.sh /home/$USERNAME/install-bigscreen-step2.sh
chown "$USERNAME":"$USERNAME" /home/$USERNAME/install-bigscreen-step2.sh
chmod +x /home/$USERNAME/install-bigscreen-step2.sh

# Автозапуск скрипта при первом входе (через .bash_profile)
cat >> /home/$USERNAME/.bash_profile << PROFILE

# Автоустановка Plasma Bigscreen при первом входе
if [ -f ~/install-bigscreen-step2.sh ]; then
    echo ""
    echo "🚀 Обнаружен скрипт установки Plasma Bigscreen."
    echo "   Запустить автоматически? [Y/n]"
    read -r _ans
    if [[ "\$_ans" != "n" && "\$_ans" != "N" ]]; then
        bash ~/install-bigscreen-step2.sh
    fi
fi
PROFILE

CHROOT

ok "Chroot-настройка завершена"

# ══════════════════════════════════════════════════
# ШАГ 8: Размонтирование
# ══════════════════════════════════════════════════
step "Размонтирование разделов..."
umount -R /mnt
ok "Разделы размонтированы"

# ══════════════════════════════════════════════════
# ГОТОВО
# ══════════════════════════════════════════════════
echo ""
echo -e "${GREEN}${BOLD}"
cat << 'DONE'
╔══════════════════════════════════════════════════════════╗
║  ✅ Этап 1 завершён! Система установлена.               ║
╠══════════════════════════════════════════════════════════╣
║  Дальнейшие шаги:                                       ║
║                                                          ║
║  1. Вытащи флешку                                        ║
║  2. Введи:  reboot                                       ║
║  3. После загрузки войди в консоль как свой пользователь ║
║  4. Запустится скрипт установки Bigscreen автоматически  ║
║     (или вручную: bash ~/install-bigscreen-step2.sh)    ║
║  5. После завершения: sudo reboot                        ║
║                                                          ║
║  🎮 Enjoy Plasma Bigscreen!                             ║
╚══════════════════════════════════════════════════════════╝
DONE
echo -e "${NC}"
