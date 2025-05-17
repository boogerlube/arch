if [ $(id -u) = 0 ]; 
then
   echo "Do NOT run as root" 
   exit
fi

#sudo dhclient
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

#Install KDE-Plasma meta package here because of questions.
#Install greeter here too because it is vital

sudo pacman -S plasma --noconfirm --needed
sudo pacman -S sddm --noconfirm

# Install KDE packages + audio + terminal

step3pacs=(
  ark
  avahi
  cups
  dolphin
  fastfetch
  firefox
  ffmpegthumbs
  flatpak-kcm
  gwenview
  gvfs
  kalk
  kclock
  kcolorchooser
  kdialog
  kimageformats
  konsole
  krdp
  libva
  nemo
  nfs-utils
  obsidian-icon-theme
  partitionmanager
  plasma-systemmonitor
  pipewire
  pipewire-alsa
  pipewire-pulse
  pipewire-x11-bell
  pipewire-zeroconf
  pkgfile
  qt6-imageformats
  spectacle
  terminator
  wireplumber
  xdg-desktop-portal-gtk
  xwaylandvideobridge
  zimg
  )

# removed xorg from packages as KDE-Plasma now uses Wayland

sudo pacman -S "${step3pacs[@]}" --needed --noconfirm 2>&1 | tee $HOME/KDE.log

# update databases and enable services
sudo pkgfile --update
sudo systemctl enable sddm
sudo systemctl enable cups.service
sudo systemctl enable fstrim.timer
sudo systemctl enable paccache.timer
sudo systemctl enable archlinux-keyring-wkd-sync.timer
sudo systemctl enable avahi-daemon

cd ~
git clone https://aur.archlinux.org/yay.git
git clone https://github.com/AdnanHodzic/auto-cpufreq.git

cd yay
makepkg -si --noconfirm

# Load Arch theme for SDDM
yay -S archlinux-themes-sddm
echo "[Theme]" | sudo tee /etc/sddm.conf
echo "#Current=archlinux-simplyblack" | sudo tee -a /etc/sddm.conf

# chaotic-aur website:
#https://aur.chaotic.cx
