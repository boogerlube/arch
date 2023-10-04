######
##      fix the disk variable otherwise you are gonna have a bad time!
######
export disk="/dev/nvme0n1p"

# List of packages to install

step2pacs=(
  bash-completion
  btrfs-progs
  cryptsetup
  dialog
  dosfstools
  efibootmgr
  git
  iwd
  linux-headers
  man-db
  mtools
  networkmanager
  network-manager-applet
  os-prober
  pacman-contrib
  reflector
  wpa_supplicant
  xdg-utils
  xdg-user-dirs
  )

# Setup timezone and locale

ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# setup pacman keys

rm -rf /etc/pacman.d/gnupg
pacman-key --init
pacman-key --populate archlinux

# Add encryption to initramfs and setup hostname

sed -i '/^HOOKS=/ s/filesystems/encrypt &/g' /etc/mkinitcpio.conf
read -p 'Hostname? ' HOST
echo $HOST > /etc/hostname
mkinitcpio -P

# Setup necessary tools

#pacman -S --noconfirm efibootmgr linux-headers networkmanager network-manager-applet wpa_supplicant iwd
#pacman -S --noconfirm dialog os-prober mtools dosfstools reflector git bluez bluez-utils usbutils cups xdg-utils xdg-user-dirs btrfs-progs
#pacman -S --noconfirm bash-completion cryptsetup man-db pacman-contrib

pacman -S "${step2pacs[@]}" --noconfirm --needed


# Add CPU microcode to system

ucode=$(lscpu | grep "^Vendor ID:" | awk -F":" '{print $2}' | xargs)

if [[ "$ucode" == *"Intel"* ]]; then
  echo "Intel processor detected. Installing intel-ucode...."
  ARCH="intel-ucode.img"
  pacman -S --noconfirm intel-ucode
elif [[ "$ucode" == *"AMD"* ]]; then
  echo "AMD processor detected. Installing amd-ucode...."
  ARCH="amd-ucode.img"
  pacman -S --noconfirm amd-ucode
else
  echo "No Intel or AMD processor detected."
  ARCH=""
fi

# Install grub and configure it for encryption

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
# UUID=$(blkid -o value ${disk}2 | head -n1)
UUID=$(blkid -s UUID -o value ${disk}2)
CMD='cryptdevice=UUID='$UUID':root:allow-discards root=/dev/mapper/root'
sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s|loglevel=3|$CMD &|g" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

#  Setup swap

chattr +C /swap
read -p 'Swap size in GB? ' MEM
MEMSIZE="$MEM""G"
btrfs filesystem mkswapfile --size $MEMSIZE /swap/swapfile
echo "/swap/swapfile none swap defaults 0 0" | tee -a /etc/fstab

#    Add user

#passwd root
useradd -m bob
passwd bob
#create file bob in /etc/sudoers.d
echo "bob ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/bob

#  copy last step to user directory 'cause we gotta reboot!

mkdir /home/bob/arch
cp /root/* /home/bob/arch/

echo -e "\n\nPlease reboot now\n"