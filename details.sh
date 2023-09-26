tar -xvf post-install.tar.gz
cp -r Wallpapers ~/Pictures/
cp ./arch-shell/.* ~
cat fstab.txt | sudo tee -a /etc/fstab
sudo mkdir /media
sudo mkdir /media/pinky
sudo mkdir /media/share
sudo mkdir /media/torrent
sudo mount -a
source ~/.bashrc
sudo mkdir /etc/samba
sudo cp smb.conf /etc/samba/