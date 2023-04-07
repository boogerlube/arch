sudo pacman -S cinnamon lightdm-gtk-greeter firefox terminator
sudo systemctl enable lightdm
sudo systemctl enable NetworkManager
sudo systemctl enable cups.service

cd ~
git clone https://aur.archlinux.org/yay.git
git clone https://github.com/AdnanHodzic/auto-cpufreq.git

sudo pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key FBA220DFC880C036
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

sudo echo '[chaotic-aur]' | tee -a /etc/pacman.conf
sudo echo 'Include = /etc/pacman.d/chaotic-mirrorlist' | tee -a /etc/pacman.conf
sudo cp /etc/pacman.conf /etc/pacman.conf.sav
sed -i 's/#\[multilib\]/\[multilib\]/g' /etc/pacman.conf
sed -i 's/#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/g' /etc/pacman.conf
