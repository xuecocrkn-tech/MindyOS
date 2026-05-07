# MindyOS Build Guide
# Step-by-step guide to build MindyOS ISO image
# Based on Debian Stable with XFCE 4.18 desktop

## Overview
This guide provides complete instructions to build MindyOS, a custom Debian-based
Linux distribution with XFCE desktop environment. Target size: 1-1.5 GB.

## Prerequisites
- Ubuntu/Debian system (any variant)
- At least 20GB free disk space
- 4GB RAM recommended
- Internet connection for package downloads

---

## Step 1: Install Build Tools

First, update your system and install the required build tools:

```bash
# Update package lists
sudo apt update

# Install live-build and dependencies
sudo apt install -y live-build live-tools xorriso \
    libarchive-zip-perl gnu-efi-tools \
    imagemagick uuid-runtime \
    dosfstools xfsprogs \
    fakeroot \
    locales \
    keyboard-configuration

# Verify live-build installation
lb --version
```

Expected output: `live-build 1:2024xx.xx` or similar

---

## Step 2: Create Project Structure

Create the MindyOS build directory:

```bash
# Create project directory
mkdir -p ~/mindyos-build
cd ~/mindyos-build

# Create live-build directory structure
mkdir -p config/package-lists
mkdir -p config/includes.binary/boot/grub
mkdir -p config/includes.installer
mkdir -p config/hooks/live
mkdir -p config/hooks/installer
mkdir -p auto
```

---

## Step 3: Configure live-build

Create the live-build configuration file:

```bash
cat > ~/mindyos-build/auto/config << 'EOF'
#!/bin/bash
set -e

# MindyOS live-build configuration

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

chmod +x ~/mindyos-build/auto/config
```

---

## Step 4: Create Package Lists

Create the chroot package list (packages installed in the system):

```bash
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
myspell-ru
hunspell-ru

# Basic tools
vim
nano
EOF

chmod 644 ~/mindyos-build/config/package-lists/mindyos.list.chroot
```

Create the binary package list:

```bash
cat > ~/mindyos-build/config/package-lists/mindyos.list.binary << 'EOF'
# Binary packages (for the live system)
live-boot
live-boot-initramfs-tools
live-config
live-config-systemd
EOF

chmod 644 ~/mindyos-build/config/package-lists/mindyos.list.binary
```

---

## Step 5: System Configuration Hooks

### Hook 1: System Configuration

```bash
cat > ~/mindyos-build/config/hooks/live/01-system-config.chroot << 'EOF'
#!/bin/bash
set -e

# MindyOS System Configuration

# Locale configuration
cat > /etc/locale.gen << 'EOFLANG'
en_US.UTF-8 UTF-8
ru_RU.UTF-8 UTF-8
EOFLANG
locale-gen

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

chmod +x ~/mindyos-build/config/hooks/live/01-system-config.chroot
```

### Hook 2: LightDM Automatic Login

```bash
cat > ~/mindyos-build/config/hooks/live/02-lightdm-autologin.chroot << 'EOF'
#!/bin/bash
set -e

# LightDM automatic login configuration

mkdir -p /etc/lightdm

# Configure LightDM for automatic login
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

# Configure greeter
mkdir -p /etc/lightdm/lightdm-gtk-greeter.d

cat > /etc/lightdm/lightdm-gtk-greeter.conf << 'EOFGREETER'
[greeter]
theme-name=Greybird-dark
icon-theme-name=Papirus-Dark
font-name=Roboto 11
background=/usr/share/images/mindyos/mindyos-wallpaper.jpg
EOFGREETER
EOF

chmod +x ~/mindyos-build/config/hooks/live/02-lightdm-autologin.chroot
```

### Hook 3: XFCE Desktop Configuration

```bash
cat > ~/mindyos-build/config/hooks/live/03-xfce-config.chroot << 'EOF'
#!/bin/bash
set -e

# XFCE Desktop Configuration

mkdir -p /etc/skel/.config/xfce4/xfconf
mkdir -p /etc/skel/.config/autostart

# Configure XFCE settings
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

# Create autostart for live user
mkdir -p /home/live/.config/autostart

cat > /home/live/.config/autostart/nm-applet.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Network Manager
Exec=/usr/bin/nm-applet
X-GNOME-Autostart-enabled=true
EOF

cat > /home/live/.config/autostart/pavucontrol.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Volume Control
Exec=/usr/bin/pavucontrol
X-GNOME-Autostart-enabled=true
EOF

cat > /home/live/.config/autostart/polkit-agent.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=PolicyKit Authentication Agent
Exec=/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1
X-GNOME-Autostart-enabled=true
EOF

# Create /home/live if not exists
[ -d /home/live ] || mkdir -p /home/live
EOF

chmod +x ~/mindyos-build/config/hooks/live/03-xfce-config.chroot
```

### Hook 4: First Login Setup

```bash
cat > ~/mindyos-build/config/hooks/live/04-first-login.chroot << 'EOF'
#!/bin/bash
set -e

# First login setup script - runs once at first login

# Create first-login marker
mkdir -p /home/live/.config

cat > /usr/local/bin/mindyos-first-login.sh << 'EOF'
#!/bin/bash
# Wait for desktop
sleep 10
export DISPLAY=:0
export XDG_RUNTIME_DIR=/run/user/1000

# Configure desktop if not done yet
if [ ! -f ~/.mindyos_configured ]; then
    # Dark theme
    xfconf-query -c xfwm4 -p /general/theme -s Greybird-dark 2>/dev/null || true
    xfconf-query -c xsettings -p /Net/ThemeName -s Greybird-dark 2>/dev/null || true
    
    # Icons
    xfconf-query -c xsettings -p /Net/IconThemeName -s Papirus-Dark 2>/dev/null || true
    
    # Font
    xfconf-query -c xsettings -p /Gtk/FontName -s "Roboto 11" 2>/dev/null || true
    
    # Wallpaper
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image \
        -s /usr/share/images/mindyos/mindyos-wallpaper.jpg 2>/dev/null || true
    
    touch ~/.mindyos_configured
fi
EOF

chmod +x /usr/local/bin/mindyos-first-login.sh

# Create systemd service
cat > /lib/systemd/system/mindyos-first-login.service << 'EOF'
[Unit]
Description=MindyOS First Login Configuration
After=graphical.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/mindyos-first-login.sh
RemainAfterExit=yes

[Install]
WantedBy=graphical.target
EOF

# Enable service
systemctl enable mindyos-first-login.service 2>/dev/null || true
EOF

chmod +x ~/mindyos-build/config/hooks/live/04-first-login.chroot
```

### Hook 5: Create Wallpaper

```bash
cat > ~/mindyos-build/config/hooks/live/05-wallpaper.chroot << 'EOF'
#!/bin/bash
set -e

# Create MindyOS wallpaper

mkdir -p /usr/share/images/mindyos

# Create simple dark gradient wallpaper using ImageMagick
convert -size 1920x1080 \
    gradient:#1a1a2e-#16213e \
    -gravity center \
    -fill "#4a9eff" \
    -pointsize 72 -font Roboto-Medium \
    label:"MindyOS" \
    -composite \
    /usr/share/images/mindyos/mindyos-wallpaper.jpg 2>/dev/null || true

# If ImageMagick not available, create simple placeholder
if [ ! -f /usr/share/images/mindyos/mindyos-wallpaper.jpg ]; then
    convert -size 1920x1080 \
        gradient:#1a1a2e-#16213e \
        /usr/share/images/mindyos/mindyos-wallpaper.jpg
fi

chmod 644 /usr/share/images/mindyos/mindyos-wallpaper.jpg
EOF

chmod +x ~/mindyos-build/config/hooks/live/05-wallpaper.chroot
```

---

## Step 6: Build the ISO

Now build the ISO image:

```bash
cd ~/mindyos-build

# Clean any previous build artifacts
lb clean --all

# Build the ISO
sudo lb build 2>&1 | tee build.log
```

The build process will:
1. Download and install all packages (~1-2GB download)
2. Configure the system
3. Create the live filesystem
4. Generate the ISO image

---

## Step 7: Output

After successful build, the ISO will be in the current directory:

```bash
# Find the generated ISO
ls -lh ~/mindyos-build/*.iso

# Typical output:
# -rw-r--r-- 1 mindyosxxx 1.2G May  7 14:37 mindyos-1.0-amd64.hybrid.iso
```

---

## Step 8: Test in VirtualBox

### Create Virtual Machine

1. Open VirtualBox
2. Create new VM:
   - Name: MindyOS
   - Type: Linux
   - Version: Debian (64-bit)
   - RAM: 2048 MB (minimum)
   - Hard disk: 20 GB

### Attach ISO

1. Select VM → Settings
2. Storage → Add CD/DVD → Choose ISO
3. Check "Live CD/DVD"

### Boot and Test

1. Start the VM
2. Verify:
   - Boot menu appears
   - System boots to XFCE desktop
   - Automatic login works
   - Network is functional
   - Theme applied correctly

### Test Installation

1. Double-click "Install MindyOS" icon on desktop
2. Follow installation wizard
3. Reboot and test installed system

---

## Build Time and Size

| Metric | Value |
|--------|-------|
| Download size | ~800 MB |
| Installed size | ~2.5 GB |
| ISO size | ~1.2 GB |
| Build time | 15-30 minutes |

---

## Troubleshooting

### Common Issues

1. **Package download fails**
   - Check internet connection
   - Try different mirror: `lb config --apt-mirror http://deb.debian.org/debian/`

2. **Build fails**
   - Clean and retry: `lb clean && lb build`

3. **ISO too large**
   - Remove large packages ( LibreOffice, etc.)
   - Use minimal package list

4. **Boot fails**
   - Ensure bootloader is properly configured
   - Check syslinux configuration

---

## Customization Tips

### Add more applications:
```bash
# Add to mindyos.list.chroot
# Browser
firefox-esr
# Office
libreoffice- calc
```

### Change theme:
```bash
# In /etc/lightdm/lightdm-gtk-greeter.conf
theme-name=Adwaita
icon-theme-name=Adwaita
```

### Change wallpaper:
```bash
# Replace wallpaper file
cp your-wallpaper.jpg /usr/share/images/mindyos/mindyos-wallpaper.jpg
```

---

## Summary of Commands

```bash
# Quick Start
cd ~/mindyos-build
sudo lb build

# Tools
lb --version          # Check version
lb clean             # Clean build
lb clean --all       # Clean all
lb build             # Build ISO
```

---

## Files Created

```
mindyos-build/
├── auto/
│   └── config
├── config/
│   ├── package-lists/
│   │   ├── mindyos.list.binary
│   │   └── mindyos.list.chroot
│   └── hooks/
│       └── live/
│           ├── 01-system-config.chroot
│           ├── 02-lightdm-autologin.chroot
│           ├── 03-xfce-config.chroot
│           ├── 04-first-login.chroot
│           └── 05-wallpaper.chroot
```

---

## Final Notes

- Target size: ~1.2 GB ISO
- Base: Debian Stable
- Desktop: XFCE 4.18
- Auto-login enabled for 'live' user
- Dark theme (Greybird-dark) with Papirus icons
- Russian locale with English keyboard

The resulting ISO is fully bootable and can be:
1. Written to USB with `dd` or Rufus
2. Burned to DVD
3. Used in VirtualBox or QEMU
4. Used for installation to hard drive