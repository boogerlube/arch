
# Make yerself t'home!

#sudo chown -R bob:bob ~/arch/
tar -xvf post-install.tar.gz
mv Wallpapers/ ~/Pictures/
mv ./arch-shell/.* ~
cat fstab.txt | sudo tee -a /etc/fstab
sudo mkdir -p /media/{brain,share,torrent}
sudo mount -a
source ~/.bashrc
sudo mkdir /etc/samba
sudo cp smb.conf /etc/samba/
sudo pacman -S --needed --noconfirm gvfs-smb
mkdir -p ~/.local/bin
mv scripts/* ~/.local/bin
chmod +x ~/.local/bin/*.sh
sudo cp ./sounds/* /usr/share/sounds/
mkdir -p ~/.local/share/nemo/scripts
ln -s ~/.local/bin/playlist.sh ~/.local/share/nemo/scripts/
mkdir ~/.themes
mv themes/* ~/.themes/
#mkdir ~/.local/share/cinnamon/desklets
mv desklets ~/.local/share/cinnamon/
sudo cp repair.sh /boot
sudo sed -i '/^#MAKEFLAGS=/ s/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/g' /etc/makepkg.conf

# restore cinnamon settings if cinnamon is installed
if [ -e  /usr/bin/cinnamon ] ; then
      dconf load / < dconf.conf
fi


#fix vscode bug with nemo
xdg-mime default nemo.desktop inode/directory

#set theme
gsettings set org.gnome.desktop.interface gtk-theme 'CBlack'


