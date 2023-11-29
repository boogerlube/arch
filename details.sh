
# Make yerself t'home!

#sudo chown -R bob:bob ~/arch/
tar -xvf post-install.tar.gz
mv -r Wallpapers ~/Pictures/
mv ./arch-shell/.* ~
cat fstab.txt | sudo tee -a /etc/fstab
sudo mkdir -p /media/{pinky,share,torrent}
sudo mount -a
source ~/.bashrc
sudo mkdir /etc/samba
sudo cp smb.conf /etc/samba/
mkdir ~/.local/bin
mv scripts/* ~/.local/bin
chmod +x ~/.local/bin/*.sh
sudo cp ./sounds/* /usr/share/sounds/
ln -s ~/.local/bin/playlist.sh ~/.local/share/nemo/scripts/
mkdir ~/.themes
mv themes/* ~/.themes/
#mkdir ~/.local/share/cinnamon/desklets
mv desklets ~/.local/share/cinnamon/
sudo cp repair.sh /boot

#restore cinnamon settings
dconf load / < dconf.conf
#dconf load /org/cinnamon/sounds/ < sounds.txt
#dconf load /org/cinnamon/desktop/keybinding/ < shortcut-settings.conf

#fix vscode bug with nemo
xdg-mime default nemo.desktop inode/directory

