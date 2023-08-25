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

read -p "Press [enter] to continue"

#sudo pacman -S xorg-server xorg-server-utils xorg-xinit mesa
sudo pacman -S --needed --noconfirm cinnamon lightdm lightdm-gtk-greeter firefox terminator pipewire wireplumber pipewire-jack pipewire-pulse pipewire-alsa
sudo pacman -S --needed --noconfirm pipewire-x11-bell pipewire-zeroconf neofetch nfs-utils pkgfile
sudo pkgfile --update
sudo systemctl enable lightdm
sudo systemctl enable NetworkManager
sudo systemctl enable cups.service
sudo systemctl enable fstrim.timer
sudo systemctl enable archlinux-keyring-wkd-sync.timer

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

#sudo pacman -S linux-lts
#sudo grub-mkconfig -o /boot/grub/grub.cfg

sudo pacman -Sy
cd yay
makepkg -si

#https://aur.chaotic.cx