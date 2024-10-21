if [ $(id -u) = 0 ]; 
then
   echo "Do NOT run as root" 
   exit
fi

sudo pacman -Syu
sudo pacman -S kodi
sudo pacman -S kodi-audioencoder-* kodi-pvr-*