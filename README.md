# MindyOS

A custom Debian-based Linux distribution with XFCE desktop environment.

![MindyOS](https://img.shields.io/badge/OS-Debian%20Stable-blue)
![Desktop-XFCE%204.18-blue](https://img.shields.io/badge/Desktop-XFCE%204.18-blue)
![License-MIT-green](https://img.shields.io/badge/License-MIT-green)

## About

MindyOS is a lightweight, bootable Linux distribution built with [live-build](https://live-team.debian.org/live-build.en.html). It features:

- **XFCE 4.18** - Fast and lightweight desktop environment
- **Automatic login** - Boots directly to desktop
- **Dark theme** - Greybird-dark with Papirus icons
- **Russian locale** - Russian language with English keyboard
- **Compact size** - ~1.2 GB ISO image

## Features

| Feature | Value |
|---------|-------|
| Base | Debian Stable |
| Desktop | XFCE 4.18 |
| Architecture | amd64 (64-bit) |
| Auto-login | Yes (user: `live`) |
| Theme | Greybird-dark |
| Icons | Papirus-Dark |
| Font | Roboto |
| System Language | Russian |
| Keyboard | English |

## Quick Start

### Build from Source

```bash
# Install dependencies (Ubuntu/Debian)
sudo apt update
sudo apt install -y live-build live-tools xorriso imagemagick uuid-runtime fakeroot locales

# Clone or download this repository
git clone https://github.com/xuecocrkn-tech/MindyOS.git
cd MindyOS

# Run the build
sudo lb build
```

The resulting ISO will be in the current directory.

### Pre-built ISO

Download the latest ISO from the [Releases](https://github.com/xuecocrkn-tech/MindyOS/releases) page.

## Usage

### Burn to USB

```bash
# Find your USB device
sudo fdisk -l

# Write ISO to USB (replace /dev/sdX with your device)
sudo dd if=mindyos-*.iso of=/dev/sdX bs=4M status=progress
```

### Run in VirtualBox

1. Create a new VM (Debian 64-bit, 2GB RAM, 20GB storage)
2. Attach the ISO to the virtual CD/DVD drive
3. Boot and enjoy!

### Install to Hard Drive

1. Boot from the ISO
2. Double-click "Install MindyOS" on the desktop
3. Follow the installation wizard

## Default Credentials

| Username | Password |
|----------|----------|
| live | live |

## Build Customization

### Add Packages

Edit `config/package-lists/mindyos.list.chroot`:

```
# Add your packages here
package-name
```

### Change Theme

Edit `config/hooks/live/02-lightdm-autologin.chroot`:

```bash
theme-name=YourTheme
icon-theme-name=YourIconTheme
```

### Change Wallpaper

Replace `/usr/share/images/mindyos/mindyos-wallpaper.jpg` in the hook scripts.

## Project Structure

```
MindyOS/
├── MindyOS-Build-Guide.md    # Detailed build guide
├── build-mindyos.sh          # Automated build script
├── auto/config             # live-build configuration
├── config/
│   ├── package-lists/      # Package lists
│   └── hooks/live/        # System configuration hooks
└── README.md              # This file
```

## License

MIT License - See [LICENSE](LICENSE) for details.

## Credits

- [Debian](https://www.debian.org/) - Base distribution
- [XFCE](https://www.xfce.org/) - Desktop environment
- [Greybird theme](https://github.com/shimmerproject/Greybird)
- [Papirus icons](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme)

---

Built with ♥ using live-build