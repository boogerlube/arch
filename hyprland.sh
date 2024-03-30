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

# Add chaotic-aur and multilib to pacman
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

echo '[chaotic-aur]' | sudo tee -a /etc/pacman.conf
echo 'Include = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
echo '[multilib]' | sudo tee -a /etc/pacman.conf
echo 'Include = /etc/pacman.d/mirrorlist' | sudo tee -a /etc/pacman.conf
sudo pacman -Sy

# update pacman.conf for color and threads
sudo sed -i 's/#Color/Color/' /etc/pacman.conf
sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

# Install Hyprland + audio + terminal
hypr3pacs=(
  avahi
  brightnessctl
  cava
  cmus
  cups
  dunst
  fastfetch
  file-roller
  firefox
  ffmpeg
  ffmpegthumbnailer
  grimblast-git
  hyprland
  hyprpaper
  hyprpicker-git
  inter-font
  kitty
  libpipewire
  libva
  libpulse
  nemo
  neovim
  nfs-utils
  noise-suppression-for-voice
  nordic-theme
  noto-fonts
  noto-fonts-emoji
  nwg-look
  otf-firamono-nerd
  otf-sora
  pamixer
  papirus-icon-theme
  pavucontrol
  pipewire
  pipewire-alsa
  pipewire-jack
  pipewire-pulse
  pkgfile
  playerctl
  polkit-gnome
  rofi
  sddm
  spdlog
  starship
  swaybg
  swayidle
  swaylock-effects
  terminator
  thunar
  thunar-archive-plugin
  ttf-comfortaa
  ttf-fantasque-nerd
  ttf-font-awesome
  ttf-icomoon-feather
  ttf-iosevka-nerd
  ttf-jetbrains-mono-nerd
  ttf-nerd-fonts-symbols-common
  tumbler
  udiskie
  ulauncher
  viewnior
  waybar
  wf-recorder
  wireplumber
  wl-clipboard
  wlogout
  wofi
  xdg-desktop-portal-hyprland
  yay
  zimg
  )

sudo pacman -S --needed --noconfirm "${hypr3pacs[@]}"

#update databases and enable services
sudo pkgfile --update
sudo systemctl enable NetworkManager
sudo systemctl enable cups.service
sudo systemctl enable fstrim.timer
sudo systemctl enable paccache.timer
sudo systemctl enable archlinux-keyring-wkd-sync.timer
sudo systemctl enable sddm
sudo systemctl enable bluetooth
sudo systemctl enable avahi-daemon
sudo systemctl enable systemd-boot-update

# Add user to input group for waybar
sudo usermod -aG input $USER

#clone tools not in pacman
#cd ~
#git clone https://aur.archlinux.org/yay.git
#git clone https://github.com/AdnanHodzic/auto-cpufreq.git

# load aur pacs
#cd yay
#makepkg -si
#yay -S waybar-hyprland
#yay -S waybar-hyprland-git
yay -S archlinux-themes-sddm
yay -S sway-audio-idle-inhibit-git
yay -S hypridle

#Setup theme for sddm
echo "[Theme]" | sudo tee /etc/sddm.conf
echo "Current=archlinux-simplyblack" | sudo tee -a /etc/sddm.conf

#start sound services
systemctl --user start pipewire.service
systemctl --user start pipewire-pulse.service
systemctl --user start wireplumber.service

echo -e "\n\nPlease reboot now.\n"

# chaotic-aur website:
#https://aur.chaotic.cx