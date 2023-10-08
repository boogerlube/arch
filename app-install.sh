if : >/dev/tcp/8.8.8.8/53; then
  echo 'Internet available.'
else
  echo 'Offline.';exit
fi

#install all necessary packages.
sudo pacman -S --needed --noconfirm - < arch_pkgs.txt

#fix vscode bug with nemo
xdg-mime default nemo.desktop inode/directory

#set lightdm-slick-greeter as default greeter
#sudo sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf

#setup cups to start with system
#sudo systemctl enable --now cups

#update mlocate database
sudo updatedb

## If gnome apps are slow to launch execute the line below:
#sudo pacman -R xdg-desktop-portal-gnome



