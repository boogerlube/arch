if : >/dev/tcp/8.8.8.8/53; then
  echo 'Internet available.'
else
  echo 'Offline.';exit
fi

#install all necessary packages.

sudo pacman -S --needed --noconfirm - < arch_pkgs.txt

#sudo pacman -S --needed --noconfirm gvfs-smb p7zip unrar tar rsync file-roller terminator git
#sudo pacman -S --needed --noconfirm a52dec faac faad2 flac jasper lame libdca libdv libmad libmpeg2 libtheora libvorbis libxv wavpack x264 xvidcore
#sudo pacman -S --needed --noconfirm arc-gtk-theme papirus-icon-theme gnome-keyring copyq pinta
#sudo pacman -S --needed --noconfirm system-config-printer blueman networkmanager-openvpn hplip arandr lsof
#sudo pacman -S --needed --noconfirm remmina freerdp gnome-system-monitor maui-pix audacious okular gnome-screenshot
#sudo pacman -S --needed --noconfirm gdu gdu htop btop putty bat fzf tldr eza gprename ristretto flameshot pacman-contrib
#sudo pacman -S --needed --noconfirm gnome-characters obsidian-icon-theme deepin-icon-theme inotify-tools gnome-terminal
#sudo pacman -S --needed --noconfirm libreoffice-fresh hunspell hunspell-en_us mediainfo-gui mpv notepadqq foliate ebook-tools
#sudo pacman -S --needed --noconfirm cups-pdf czkawka mullvad-vpn gnome-calculator gnome-clocks mlocate sshfs
#sudo pacman -S --needed --noconfirm yt-dlp rtmpdump atomicparsley aria2 python-mutagen python-pycryptodomex python-websockets
#sudo pacman -S --needed --noconfirm bluez bluez-utils usbutils
#sudo systemctl enable --now cups
#sudo pacman -S --needed --noconfirm google-chrome
#sudo pacman -S --needed --noconfirm ttf-ms-fonts
#sudo pacman -S --needed --noconfirm gnome-disk-utility
#sudo pacman -S --needed --noconfirm lightdm-slick-greeter
#sudo pacman -S --needed --noconfirm lightdm-settings
#sudo sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf
#yay -S pamac-aur
#yay -S albert
#yay -S mullvad-vpn
#yay -S timeshift
#yay -S timeshift-autosnap
#yay -S netdiscover
#yay -S mp3gain

#update mlocate database

sudo updatedb



## If gnome apps are slow to lauch execute the line below:
#sudo pacman -R xdg-desktop-portal-gnome



