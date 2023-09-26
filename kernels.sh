# select the proper disk

export disk="/dev/nvme0n1p"

# make sure we run as root 

if [ $(id -u) != 0 ]; 
then
   echo "Must run as root" 
   exit
fi

# load lts kernel if not already loaded

sudo pacman -S --needed --noconfirm linux-lts

# determine cpu architecture

ucode=$(lscpu | grep "^Vendor ID:" | awk -F":" '{print $2}' | xargs)

if [[ "$ucode" == *"Intel"* ]]; then
  echo "Intel processor detected. Installing intel-ucode...."
  ARCH="intel-ucode.img"
elif [[ "$ucode" == *"AMD"* ]]; then
  echo "AMD processor detected. Installing amd-ucode...."
  ARCH="amd-ucode.img"
else
  echo "No Intel or AMD processor detected."
  ARCH=""
fi

# get disk UUID

UUID=$(blkid -s UUID -o value ${disk}2)

# create LTS loader

echo "title    Arch Linux LTS" > /boot/loader/entries/arch-lts.conf
echo "linux    /vmlinuz-linux-lts" >> /boot/loader/entries/arch-lts.conf
echo "initrd   /"$ARCH >> /boot/loader/entries/arch-lts.conf
echo "initrd   /initramfs-linux-lts.img" >> /boot/loader/entries/arch-lts.conf
echo "options  cryptdevice=UUID="$UUID":root:allow-discards root=/dev/mapper/root rootflags=subvol=@ rd.luks.options=discard rw" >> /boot/loader/entries/arch-lts.conf

# create fallback loader

echo "title    Arch Linux (fallback)" > /boot/loader/entries/arch-fallback.conf
echo "linux    /vmlinuz-linux" >> /boot/loader/entries/arch-fallback.conf
echo "initrd   /"$ARCH >> /boot/loader/entries/arch-fallback.conf
echo "initrd   /initramfs-linux-fallback.img" >> /boot/loader/entries/arch-fallback.conf
echo "options  cryptdevice=UUID="$UUID":root:allow-discards root=/dev/mapper/root rootflags=subvol=@ rd.luks.options=discard rw" >> /boot/loader/entries/arch-fallback.conf

#create LTS fallback loader

echo "title    Arch Linux LTS (fallback)" > /boot/loader/entries/arch-lts-fallback.conf
echo "linux    /vmlinuz-linux-lts" >> /boot/loader/entries/arch-lts-fallback.conf
echo "initrd   /"$ARCH >> /boot/loader/entries/arch-lts-fallback.conf
echo "initrd   /initramfs-linux-lts-fallback.img" >> /boot/loader/entries/arch-lts-fallback.conf
echo "options  cryptdevice=UUID="$UUID":root:allow-discards root=/dev/mapper/root rootflags=subvol=@ rd.luks.options=discard rw" >> /boot/loader/entries/arch-lts-fallback.conf
