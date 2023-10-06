
# Make yerself t'home!

#sudo chown -R bob:bob ~/arch/
tar -xvf post-install.tar.gz
cp -r Wallpapers ~/Pictures/
cp ./arch-shell/.* ~
cat fstab.txt | sudo tee -a /etc/fstab
sudo mkdir -p /media/{pinky,share,torrent}
sudo mount -a
source ~/.bashrc
sudo mkdir /etc/samba
sudo cp smb.conf /etc/samba/
mkdir ~/.local/bin
cp scripts/* ~/.local/.bin
chmod +x ~/.local/bin/*.sh
sudo cp ./sounds/* /usr/share/sounds/
dconf load /org/cinnamon/sounds/ < sounds.txt
dconf load /org/cinnamon/desktop/keybinding/ < shortcut-settings.conf
ln -s ~/.local/bin/playlist.sh ~/.local/share/nemo/scripts/

#fix vscode bug with nemo
xdg-mime default nemo.desktop inode/directory

#update pacman.conf for color and threads
sudo sed -i 's/#Color/Color/' /etc/pacman.conf
sudo sed -i s/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf