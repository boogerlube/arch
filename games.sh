########################################################################################
###                                                                                  ###
###                         Install game tools for Arch                              ###
###                                                                                  ###
########################################################################################

if [ $(id -u) = 0 ]; 
then
   echo "Do NOT run as root" 
   exit
fi

# update package cache
sudo pacman -Sy

gamepacs=(
   alsa-lib 
   alsa-plugins 
   discord 
   flatpak 
   gamemode 
   gamescope 
   giflib 
   gnutls 
   goverlay 
   gst-plugins-base-libs 
   gtk3
   kdialog 
   lib32-alsa-lib
   lib32-alsa-plugins 
   lib32-gamemode
   lib32-giflib 
   lib32-gnutls 
   lib32-gst-plugins-base-libs 
   lib32-gtk3
   lib32-libgpg-error 
   lib32-libjpeg-turbo 
   lib32-libldap 
   lib32-libpng 
   lib32-libpulse 
   lib32-libva 
   lib32-libxcomposite 
   lib32-libxinerama 
   lib32-libxslt 
   lib32-mangohud 
   lib32-mpg123 
   lib32-ncurses 
   lib32-openal
   lib32-opencl-icd-loader 
   lib32-sqlite 
   lib32-v4l-utils 
   lib32-vulkan-icd-loader 
   libgpg-error 
   libjpeg-turbo 
   libldap 
   libpng 
   libpulse 
   libva 
   libxcomposite 
   libxinerama 
   libxslt 
   lutris 
   mangohud 
   mpg123 
   ncurses 
   obs-studio 
   openal 
   opencl-icd-loader
   python-kivy 
   solaar
   sqlite 
   steam 
   v4l-utils 
   vulkan-icd-loader 
   wine-staging 
   winetricks
   xboxdrv 
  )

  yaypacs=(
    dxvk-bin
    lib32-vkbasalt
    proton-ge-custom-bin
    vkbasalt 
    xone-dkms 
  )

sudo pacman -S "${gamepacs[@]}" --needed --noconfirm
yay -S --noconfirm --needed "${yaypacs[@]}"

sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

#echo "Installing AMD GPU drivers and tools"
#    # Install AMD drivers and tools
#    sudo pacman -S --noconfirm mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader
#    yay -S --noconfirm lact
    
#echo "Installing Nvidia GPU drivers"
#    # Install Nvidia drivers and tools
#    sudo pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils nvidia-settings opencl-nvidia

