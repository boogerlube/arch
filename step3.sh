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

# Install Cinnamon DE base + audio + terminal

step3pacs=(
  cinnamon
  cups
  firefox
  lightdm
  lightdm-gtk-greeter
  neofetch
  nfs-utils
  pipewire
  pipewire-alsa
  pipeware-jack
  pipewire-pulse
  pipewire-x11-bell
  pipewire-zeroconf
  pkgfile
  terminator
  wireplumber
  )

hypr3pacs=(
  adobe-source-code-pro-fonts
  brightnessctl
  dunst
  ffmpeg
  ffmpegthumbnailer
  grimblast-git
  hyprland
  hyprpicker-git
  inter-font
  kitty
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
  playerctl
  polkit-gnome
  rofi
  sddm-git
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
  waybar-hyprland
  wf-recorder
  wl-clipboard
  wlogout
  cups
  firefox
  lightdm
  lightdm-gtk-greeter
  neofetch
  nfs-utils
  pipewire
  pipewire-alsa
  pipeware-jack
  pipewire-pulse
  pipewire-x11-bell
  pipewire-zeroconf
  pkgfile
  terminator
  wireplumber
  )

pacman -S "${hypr3pacs[@]}" --noconfirm --needed

#update databases and enable services
sudo pkgfile --update
#sudo systemctl enable lightdm
sudo systemctl enable NetworkManager
sudo systemctl enable cups.service
sudo systemctl enable fstrim.timer
sudo systemctl enable archlinux-keyring-wkd-sync.timer

#set lightdm-slick-greeter as default greeter
#sudo sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf

cd ~
git clone https://aur.archlinux.org/yay.git
git clone https://github.com/AdnanHodzic/auto-cpufreq.git

sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

echo '[chaotic-aur]' | sudo tee -a /etc/pacman.conf
echo 'Include = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
echo '[multilib]' | sudo tee -a /etc/pacman.conf
echo 'Include = /etc/pacman.d/mirrorlist' | sudo tee -a /etc/pacman.conf

#install lts kernel
#sudo pacman -S linux-lts
#sudo grub-mkconfig -o /boot/grub/grub.cfg

sudo pacman -Sy
cd yay
makepkg -si

# chaotic-aur website:
#https://aur.chaotic.cx