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


# Install Cinnamon DE base + audio + terminal

step3pacs=(
  avahi
  cinnamon
  cups
  fastfetch
  firefox
  flameshot
  gvfs
  gnome-keyring
  libsecret
  libva
  lightdm
  lightdm-gtk-greeter
  lightdm-settings
  lightdm-slick-greeter
  nfs-utils
  obsidian-icon-theme
  pipewire
  pipewire-alsa
  pipewire-jack
  pipewire-pulse
  pipewire-x11-bell
  pipewire-zeroconf
  pkgfile
  terminator
  wireplumber
  yay
  zimg
  )

sudo pacman -S "${step3pacs[@]}" --needed --noconfirm

# update databases and enable services
sudo pkgfile --update
sudo systemctl enable lightdm
sudo systemctl enable cups.service
sudo systemctl enable fstrim.timer
sudo systemctl enable paccache.timer
sudo systemctl enable archlinux-keyring-wkd-sync.timer
sudo systemctl enable bluetooth
sudo systemctl enable systemd-boot-update
sudo systemctl enable avahi-daemon

# set lightdm-slick-greeter as default greeter
sudo sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf

#cd ~
git clone https://aur.archlinux.org/yay.git
#git clone https://github.com/AdnanHodzic/auto-cpufreq.git

cd ~/yay
makepkg -si --noconfirm

#install lts kernel
#sudo pacman -S linux-lts
#sudo grub-mkconfig -o /boot/grub/grub.cfg

# chaotic-aur website:
#https://aur.chaotic.cx