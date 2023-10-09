if [ $(id -u) = 0 ]; 
then
   echo "Do NOT run as root" 
   exit
fi

sudo dhclient
ip a

if : >/dev/tcp/8.8.8.8/53; then
  echo 'Internet available.'
else
  echo 'Offline.';exit
fi

#read -p "Press [enter] to continue"

# Add chaotic-aur and multilib to pacman

sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

echo '[chaotic-aur]' | sudo tee -a /etc/pacman.conf
echo 'Include = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
echo '[multilib]' | sudo tee -a /etc/pacman.conf
echo 'Include = /etc/pacman.d/mirrorlist' | sudo tee -a /etc/pacman.conf
sudo pacman -Sy

# for some reason freaking adobe-source-code-pro-fonts keeps getting installed
sudo pacman -R adobe-source-code-pro-fonts

# Install Hyprland + audio + terminal


hypr3pacs=(
  brightnessctl
  dunst
  ffmpeg
  ffmpegthumbnailer
  grimblast-git
  hyprland
  hyprpicker-git
  inter-font
  kitty
  libpipewire
  libva
  libpulse
  nemo
  neovim
  noise-suppression-for-voice
  nordic-theme
  noto-fonts
  noto-fonts-emoji
  nwg-look-bin
  otf-firamono-nerd
  otf-sora
  pamixer
  papirus-icon-theme
  pavucontrol
  pipewire
  pipewire-alsa
  pipewire-jack
  pipewire-pulse
  playerctl
  polkit-gnome
  rofi
  sddm-git
  spdlog
  starship
  swaybg
  swaylock-effects
  thunar
  thunar-archive-plugin
  ttf-comfortaa
  ttf-fantasque-nerd
  ttf-icomoon-feather
  ttf-iosevka-nerd
  ttf-jetbrains-mono-nerd
  ttf-nerd-fonts-symbols-common
  tumbler
  viewnior
  wf-recorder
  wireplumber
  wl-clipboard
  wlogout
  wofi
  zimg
  cups
  firefox
  neofetch
  nfs-utils
  pkgfile
  terminator
  )

sudo pacman -S "${hypr3pacs[@]}"

read -p "Press [enter] to continue"

#update databases and enable services
sudo pkgfile --update
sudo systemctl enable NetworkManager
sudo systemctl enable cups.service
sudo systemctl enable fstrim.timer
sudo systemctl enable archlinux-keyring-wkd-sync.timer

cd ~
git clone https://aur.archlinux.org/yay.git
git clone https://github.com/AdnanHodzic/auto-cpufreq.git

# load aur pacs

cd yay
makepkg -si

yay -S waybar-hyprland

systemctl --user start pipewire.service
systemctl --user start pipewire-pulse.service
systemctl --user start wireplumber.service

echo -e "\n\nPlease reboot now.\n"

#install lts kernel
#sudo pacman -S linux-lts
#sudo grub-mkconfig -o /boot/grub/grub.cfg



# chaotic-aur website:
#https://aur.chaotic.cx