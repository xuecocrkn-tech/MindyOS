#!/bin/bash
# MindyOS Build Script - Automated setup and build
# Run this script on a clean Ubuntu/Debian system

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        log_warn "Running as root - this is fine for building"
    fi
}

# Install dependencies
install_deps() {
    log_info "Installing build dependencies..."
    
    sudo apt update
    sudo apt install -y \
        live-build \
        live-tools \
        xorriso \
        libarchive-zip-perl \
        gnu-efi-tools \
        imagemagick \
        uuid-runtime \
        dosfstools \
        xfsprogs \
        fakeroot \
        locales \
        keyboard-configuration \
        && log_info "Dependencies installed" || log_error "Failed to install dependencies"
}

# Create project structure
create_structure() {
    log_info "Creating project structure..."
    
    mkdir -p ~/mindyos-build/config/package-lists
    mkdir -p ~/mindyos-build/config/includes.binary
    mkdir -p ~/mindyos-build/config/hooks/live
    mkdir -p ~/mindyos-build/auto
    
    log_info "Structure created at ~/mindyos-build"
}

# Create auto/config
create_config() {
    log_info "Creating configuration files..."
    
    cat > ~/mindyos-build/auto/config << 'EOF'
#!/bin/bash
set -e

lb config no \
    --architectures amd64 \
    --bootloader syslinux \
    --distribution stable \
    --linux-flavours amd64 \
    --iso-volume "MindyOS" \
    --image-name "mindyos" \
    --source false \
    --apt apt \
    --apt-indices true \
    --apt-recommends true \
    --apt-secured true \
    --binary-images hybrid \
    --hybrid-options "--eltivefs-uuids" \
    --bootloaders syslinux \
    --checksums md5 \
    --debian-installer live \
    --debian-installer-gui true \
    --firmware false \
    --memtest none \
    --tasks-tasks "standard,xfce" \
    --iso-publisher "MindyOS Team" \
    --iso-preparer "MindyOS" \
    --iso-volume "MindyOS" \
    --linux-packages linux-image \
    --binary-format iso-hybrid
EOF
}

# Create package lists
create_packages() {
    cat > ~/mindyos-build/config/package-lists/mindyos.list.chroot << 'EOF'
# Core System
linux-image-amd64
live-boot
live-boot-initramfs-tools
live-config
live-config-systemd
fake-hwclock

# XFCE Desktop Environment
xfce4
xfce4-goodies
thunar
thunar-archive-plugin
mousepad
xfce4-terminal
xfconf
xfwm4
libxfce4ui
exo-utils
garcon

# Display Manager and Greeter
lightdm
lightdm-gtk-greeter
gtk2-engines
gtk3-engines

# Utilities
file-roller
xarchiver
ristretto
parole
gnome-calculator
xfce4-taskmanager

# Fonts
fonts-roboto
fonts-dejavu
fonts-noto

# Icons and Themes
greybird-gtk-theme
papirus-icon-theme

# Desktop Base
desktop-base

# System Tools
hddtemp
lm-sensors
acpi
policykit-1
policykit-1-gnome

# File Systems
gvfs
gvfs-backends
ntfs-3g
pmount
udisks2
polkit-gnome

# Localization
locales
locales-all
keyboard-configuration
console-setup

# Network
network-manager
network-manager-gnome
openssh-client
openssh-server

# X11
x11-apps
x11-utils
xserver-xorg
xserver-xorg-video-all

# Audio
pulseaudio
pavucontrol

# Documentation
hyphen-ru
hunspell-ru

# Basic tools
vim
nano
git
EOF

    cat > ~/mindyos-build/config/package-lists/mindyos.list.binary << 'EOF'
live-boot
live-boot-initramfs-tools
live-config
live-config-systemd
EOF
}

# Create hooks
create_hooks() {
    # System config hook
    cat > ~/mindyos-build/config/hooks/live/01-system-config.chroot << 'EOF'
#!/bin/bash
set -e

# Locale configuration
cat > /etc/locale.gen << 'EOFLANG'
en_US.UTF-8 UTF-8
ru_RU.UTF-8 UTF-8
EOFLANG
locale-gen
update-locale LANG=ru_RU.UTF-8

# Keyboard configuration
cat > /etc/default/keyboard << 'EOFKEYBOARD'
XKBMODEL=pc105
XKBLAYOUT=us,ru
XKBVARIANT=,
XKBOPTIONS=grp:ctrl_shift_toggle
EOFKEYBOARD

# Hostname
echo "mindyos" > /etc/hostname
echo "127.0.1.1    mindyos" >> /etc/hosts

# Set timezone
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
EOF

    # LightDM autologin hook
    cat > ~/mindyos-build/config/hooks/live/02-lightdm-autologin.chroot << 'EOF'
#!/bin/bash
set -e

mkdir -p /etc/lightdm

cat > /etc/lightdm/lightdm.conf << 'EOFLDM'
[LightDM]
runxserver=true

[Seat:*]
autologin-user=live
autologin-user-timeout=0

[Seat:lightdm-autologin]
greeter-session=lightdm-gtk-greeter
session-wrapper=lightdm-xsession
EOFLDM

mkdir -p /etc/lightdm/lightdm-gtk-greeter.d
cat > /etc/lightdm/lightdm-gtk-greeter.conf << 'EOFGREETER'
[greeter]
theme-name=Greybird-dark
icon-theme-name=Papirus-Dark
font-name=Roboto 11
EOFGREETER
EOF

    # XFCE config hook
    cat > ~/mindyos-build/config/hooks/live/03-xfce-config.chroot << 'EOF'
#!/bin/bash
set -e

mkdir -p /etc/skel/.config/xfce4/xfconf
mkdir -p /etc/skel/.config/autostart
mkdir -p /home/live/.config/autostart

cat > /etc/skel/.config/xfce4/xfconf/xfce4-perchannel.xml << 'EOFXFCF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="theme" type="string" value="Greybird-dark"/>
</channel>
<channel name="xsettings" version="1.0">
  <property name="Net/ThemeName" type="string" value="Greybird-dark"/>
  <property name="Net/IconThemeName" type="string" value="Papirus-Dark"/>
  <property name="Gtk/FontName" type="string" value="Roboto 11"/>
</channel>
<channel name="xfce4-desktop" version="1.0">
  <property name="workspace0/image-path" type="string" value="/usr/share/images/mindyos/mindyos-wallpaper.jpg"/>
  <property name="workspace0/image-style" type="int" value="6"/>
</channel>
EOFXFCF

cat > /home/live/.config/autostart/nm-applet.desktop << 'EOFNM'
[Desktop Entry]
Type=Application
Name=Network Manager
Exec=/usr/bin/nm-applet
X-GNOME-Autostart-enabled=true
EOFNM

cat > /home/live/.config/autostart/pavucontrol.desktop << 'EOFVOL'
[Desktop Entry]
Type=Application
Name=Volume Control
Exec=/usr/bin/pavucontrol
X-GNOME-Autostart-enabled=true
EOFVOL
EOF

    # First login hook
    cat > ~/mindyos-build/config/hooks/live/04-first-login.chroot << 'EOF'
#!/bin/bash
set -e

cat > /usr/local/bin/mindyos-first-login.sh << 'SCRIPT'
#!/bin/bash
sleep 10
export DISPLAY=:0
export XDG_RUNTIME_DIR=/run/user/1000

[ ! -f ~/.mindyos_configured ] && {
    xfconf-query -c xfwm4 -p /general/theme -s Greybird-dark 2>/dev/null || true
    xfconf-query -c xsettings -p /Net/ThemeName -s Greybird-dark 2>/dev/null || true
    xfconf-query -c xsettings -p /Net/IconThemeName -s Papirus-Dark 2>/dev/null || true
    xfconf-query -c xsettings -p /Gtk/FontName -s "Roboto 11" 2>/dev/null || true
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image \
        -s /usr/share/images/mindyos/mindyos-wallpaper.jpg 2>/dev/null || true
    touch ~/.mindyos_configured
}
SCRIPT

chmod +x /usr/local/bin/mindyos-first-login.sh
EOF

    # Wallpaper hook
    cat > ~/mindyos-build/config/hooks/live/05-wallpaper.chroot << 'EOF'
#!/bin/bash
set -e

mkdir -p /usr/share/images/mindyos

convert -size 1920x1080 \
    gradient:#1a1a2e-#16213e \
    -gravity center \
    -fill "#4a9eff" \
    -pointsize 72 -font Roboto-Medium \
    label:"MindyOS" \
    -composite \
    /usr/share/images/mindyos/mindyos-wallpaper.jpg 2>/dev/null || true

[ ! -f /usr/share/images/mindyos/mindyos-wallpaper.jpg ] && {
    convert -size 1920x1080 \
        gradient:#1a1a2e-#16213e \
        /usr/share/images/mindyos/mindyos-wallpaper.jpg
}

chmod 644 /usr/share/images/mindyos/mindyos-wallpaper.jpg
EOF
}

make_executable() {
    chmod +x ~/mindyos-build/auto/config
    chmod +x ~/mindyos-build/config/hooks/live/*.chroot
}

# Build the ISO
build_iso() {
    cd ~/mindyos-build
    
    log_info "Starting ISO build..."
    log_info "This may take 15-30 minutes depending on your internet speed..."
    
    sudo lb build 2>&1 | tee build.log
    
    log_info "Build complete!"
}

# Main
main() {
    log_info "MindyOS Build Script"
    log_info "========================"
    
    check_root
    install_deps
    create_structure
    create_config
    create_packages
    create_hooks
    make_executable
    build_iso
    
    log_info "MindyOS ISO built successfully!"
    log_info "Output: ~/mindyos-build/*.iso"
}

# Run
main "$@"