# Make yerself t'home!

#check for internet
ip a

if : >/dev/tcp/8.8.8.8/53; then
  echo 'Internet available.'
else
  echo 'Offline.';exit
fi

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
sudo pacman -S --needed --noconfirm gvfs-smb gvfs-dnssd gvfs-wsdd gvfs-nfs
mkdir -p ~/.local/bin
mv scripts/* ~/.local/bin
chmod +x ~/.local/bin/*.sh
mkdir -p ~/.local/share/nemo/scripts
ln -s ~/.local/bin/playlist.sh ~/.local/share/nemo/scripts/
sudo cp repair.sh /boot
sudo sed -i '/^#MAKEFLAGS=/ s/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/g' /etc/makepkg.conf


