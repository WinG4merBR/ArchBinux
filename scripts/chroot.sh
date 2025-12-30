echo "Configurando fish..."
sudo -u wing4merbr mkdir -p /home/wing4merbr/.config/fish/
sudo -u wing4merbr curl -L -o /home/wing4merbr/.config/fish/config.fish https://raw.githubusercontent.com/WinG4merBR/ArchBinux/refs/heads/main/fish/fish.config
usermod -s /bin/fish wing4merbr

echo "Configurando serviços..."
systemctl enable NetworkManager.service
systemctl enable lightdm.service
systemctl enable systemd-resolved.service
systemctl enable tailscaled.service
systemctl enable fstrim.timer
systemctl enable pkgstats.timer
systemctl enable paccache.timer
systemctl enable pacman-filesdb-refresh.timer
systemctl enable reflector.timer

echo "Configurando swap..."
fallocate -l 16G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab
swapon --show

echo "Configurando systemd-boot..."
rm -rf /boot/EFI/systemd
rm -rf /boot/loader
bootctl install
mkdir -p /boot/loader/entries

cat > /boot/loader/loader.conf <<EOF
default arch.conf
timeout 3
editor no
EOF

cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /amd-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$ROOT_UUID rw zswap.enabled=1 zswap.compressor=zstd zswap.zpool=zsmalloc
EOF

echo "Ativando syntax highlighting no nano..."
sudo -u wing4merbr bash -c 'echo "include /usr/share/nano/*.nanorc" >> ~/.nanorc'

echo "Configurando git..."
sudo -u wing4merbr git config --global user.email "68250074+WinG4merBR@users.noreply.github.com"
sudo -u wing4merbr git config --global user.name "WinG4merBR"
sudo -u wing4merbr git config --global core.askPass /usr/bin/ksshaskpass

# A gente não pode usar arch-chroot -S justamente porque o yay falha dentro do -S
echo "Instalando yay..."
sudo -u wing4merbr bash -c 'mkdir -p /home/wing4merbr/; cd /home/wing4merbr/; git clone https://aur.archlinux.org/yay.git; cd yay; makepkg -si; cd /'

echo "Instalando shim-signed para Secure Boot..."
sudo -u wing4merbr yay -S shim-signed --noconfirm
rm -rf /boot/EFI/systemd-shim
mkdir -p /boot/EFI/systemd-shim
cp /usr/share/shim-signed/mmx64.efi /usr/share/shim-signed/shimx64.efi /boot/EFI/systemd-shim/
# Sim, o nome precisa ser grubx64
cp /boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/systemd-shim/grubx64.efi

echo "Criando entradas UEFI..."
efibootmgr --create --disk $EFI_DISK --part $EFI_PARTITION_ID --label "Linux Boot Manager" --loader '\EFI\SYSTEMD\SYSTEMD-BOOTX64.efi'
efibootmgr --create --disk $EFI_DISK --part $EFI_PARTITION_ID --label "Linux Boot Manager (Secure Boot)" --loader '\EFI\SYSTEMD-SHIM\SHIMX64.efi'

echo "Diminuindo timeout do systemd..." 
mkdir -p /usr/lib/systemd/user.conf.d/
cat > /usr/lib/systemd/user.conf.d/00-process-timeouts.conf <<EOF
[Manager]
DefaultTimeoutStopSec=5s
EOF

# https://community.kde.org/Distributions/Packaging_Recommendations#Polkit_configuration
echo "Configurando regras do polkit para timezones..."
mkdir -p /usr/share/polkit-1/rules.d/
cat > /usr/share/polkit-1/rules.d/00-ntp-and-time-zones.rules <<EOF
// Allow current user or their system services to change the system time zone and time synchronization
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.timedate1.set-timezone" || action.id == "org.freedesktop.timedate1.set-ntp") && subject.active) {
        return polkit.Result.YES;
    }
});
EOF

echo "Instalando e configurando fontes..."
mkdir -p /usr/local/share/fonts/l/
curl -L -o /usr/local/share/fonts/l/LexicaUltralegible-Regular.otf https://raw.githubusercontent.com/jacobxperez/lexica-ultralegible/refs/heads/main/fonts/otf/LexicaUltralegible-Regular.otf
curl -L -o /usr/local/share/fonts/l/LexicaUltralegible-Bold.otf https://raw.githubusercontent.com/jacobxperez/lexica-ultralegible/refs/heads/main/fonts/otf/LexicaUltralegible-Bold.otf 
curl -L -o /usr/local/share/fonts/l/LexicaUltralegible-BoldItalic.otf https://raw.githubusercontent.com/jacobxperez/lexica-ultralegible/refs/heads/main/fonts/otf/LexicaUltralegible-BoldItalic.otf 
curl -L -o /usr/local/share/fonts/l/LexicaUltralegible-Italic.otf https://raw.githubusercontent.com/jacobxperez/lexica-ultralegible/refs/heads/main/fonts/otf/LexicaUltralegible-Italic.otf
fc-cache -f -v

# These settings are in ~/.config/kdeglobals
MAIN_FONT="Lexica Ultralegible,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
FIXED_FONT="JetBrains Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
SMALL_FONT="Lexica Ultralegible,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

sudo -u wing4merbr kwriteconfig6 --file kdeglobals --group General --key font "$MAIN_FONT"
sudo -u wing4merbr kwriteconfig6 --file kdeglobals --group General --key menuFont "$MAIN_FONT"
sudo -u wing4merbr kwriteconfig6 --file kdeglobals --group General --key toolBarFont "$MAIN_FONT"
sudo -u wing4merbr kwriteconfig6 --file kdeglobals --group General --key fixed "$FIXED_FONT"
sudo -u wing4merbr kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "$SMALL_FONT"
sudo -u wing4merbr kwriteconfig6 --file kdeglobals --group WM --key activeFont "$MAIN_FONT"

echo "Instalando tema do catppuccin para o Konsole..."
sudo -u wing4merbr mkdir -p /home/wing4merbr/.local/share/konsole/
sudo -u wing4merbr curl -L -o /home/wing4merbr/.local/share/konsole/catppuccin-mocha.colorscheme https://raw.githubusercontent.com/catppuccin/konsole/refs/heads/main/themes/catppuccin-mocha.colorscheme
echo "Configurando montagem automática dos discos..."

curl -L https://raw.githubusercontent.com/WinG4merBR/ArchBinux/refs/heads/main/scripts/setup_drives.sh \
  -o /root/setup_drives.sh

chmod +x /root/setup_drives.sh
bash /root/setup_drives.sh
