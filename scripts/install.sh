loadkeys br-abnt2

lsblk

read -p "Partição do Arch Linux (Exemplo: /dev/nvme0n1p6): " ARCH_PARTITION
read -p "Partição EFI (Exemplo: /dev/nvme0n1p4): " EFI_PARTITION
read -p "Disco EFI (Exemplo: /dev/nvme0n1): " EFI_DISK
read -p "Index da Partição EFI (Exemplo: 1, é o último número da partição EFI) " EFI_PARTITION_ID

mkfs.ext4 $ARCH_PARTITION
mount $ARCH_PARTITION /mnt
mount --mkdir $EFI_PARTITION /mnt/boot

echo "Atualizando mirrors..."
reflector --country Brazil --protocol http,https --sort rate --fastest 2 --save /etc/pacman.d/mirrorlist

echo "Excluindo kernel antigo..."
rm /mnt/boot/amd-ucode.img
rm /mnt/boot/initramfs-linux.img
rm /mnt/boot/vmlinuz-linux

sudo sed -i "/\[multilib\]/,/Include/s/^#//" /etc/pacman.conf

echo "Instalando pacotes..."

# Recommended KDE packages (not EVERYTHING is actually useful, but it is a good pointer): https://community.kde.org/Distributions/Packaging_Recommendations
pkgs=(
    base
    base-devel
    linux
    linux-firmware
    pacman-contrib
    amd-ucode
    nano
    networkmanager
    git
    efibootmgr
    vi
    vim
    sudo
    curl
    wget
    zip
    unzip
    less
    rsync
    firefox
    plasma-meta
    kde-system
    lightdm
    konsole
    kwalletmanager
    fish
    reflector
    pkgstats
    screen
    cava
    tailscale
    fastfetch
    discord
    flatpak
    flatpak-kcm
    htop
    btop
    ntfs-3g
    qbittorrent
    dosfstools
    openssh
    ksshaskpass
    noto-fonts
    noto-fonts-extra
    noto-fonts-cjk
    noto-fonts-emoji
    ttf-jetbrains-mono
    inetutils
    traceroute
    mtr
    dolphin-plugins
    ffmpegthumbs
    kdeconnect
    kdegraphics-thumbnailers
    vlc
    vlc-plugins-all
    phonon-qt6-vlc
    libappindicator
    qt6-imageformats
    cups
    system-config-printer
    ark
    7zip
    arj
    lrzip
    lzop
    unarchiver
    unrar
    steam
)

pacstrap -K /mnt "${pkgs[@]}"

genfstab -U /mnt >> /mnt/etc/fstab

echo "ARCH_PARTITION=$ARCH_PARTITION" >> /mnt/.arch_install_vars
echo "EFI_PARTITION=$EFI_PARTITION" >> /mnt/.arch_install_vars
echo "EFI_DISK=$EFI_DISK" >> /mnt/.arch_install_vars
echo "EFI_PARTITION_ID=$EFI_PARTITION_ID" >> /mnt/.arch_install_vars

curl -L -o /mnt/chroot.sh https://raw.githubusercontent.com/WinG4merBR/ArchBinux/refs/heads/main/scripts/chroot.sh
echo "Rode o script /chroot.sh dentro do \"arch-chroot /mnt\" para continuar"
arch-chroot /mnt
