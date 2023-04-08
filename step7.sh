dhclient

read -p "Press [enter] to continue"

sudo pacman -S cinnamon lightdm lightdm-gtk-greeter firefox terminator pipewire wireplumber pipewire-jack pipewire-pulse pipewire-alsa
suod pacman -S pipewire-x11-bell pipewire-zeroconf
sudo systemctl enable lightdm
sudo systemctl enable NetworkManager
sudo systemctl enable cups.service

cd ~
git clone https://aur.archlinux.org/yay.git
git clone https://github.com/AdnanHodzic/auto-cpufreq.git

sudo pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key FBA220DFC880C036
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

echo '[chaotic-aur]' | sudo tee -a /etc/pacman.conf
echo 'Include = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
echo '[multilib]' | sudo tee -a /etc/pacman.conf
echo 'Include = /etc/pacman.d/mirrorlist' | sudo tee -a /etc/pacman.conf

sudo pacman -Sy