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

# Install systemd-boot and configure it for encryption

bootctl --path=/boot install
mkdir /boot/loader
mkdir /boot/loader/entries
UUID=$(blkid -s UUID -o value ${disk}2)
echo "title Arch Linux" > /boot/loader/entries/arch.conf
echo "linux /vmlinuz-linux" >> /boot/loader/entries/arch.conf
echo "initrd /"$ARCH >> /boot/loader/entries/arch.conf
echo "initrd /initramfs-linux.img" >> /boot/loader/entries/arch.conf
# enable or disable zswap
#echo "options cryptdevice=UUID="$UUID":root:allow-discards root=/dev/mapper/root rootflags=subvol=@ rd.luks.options=discard rw" >> /boot/loader/entries/arch.conf
echo "options cryptdevice=UUID="$UUID":root:allow-discards root=/dev/mapper/root rootflags=subvol=@ rd.luks.options=discard rw zswap.enabled=0" >> /boot/loader/entries/arch.conf
echo "default  arch.conf" > /boot/loader/loader.conf
echo "timeout  4" >> /boot/loader/loader.conf
echo "console-mode max" >> /boot/loader/loader.conf
echo "editor   no" >> /boot/loader/loader.conf


#  Setup swap file

#chattr +C /swap
#read -p 'Swap size in GB? ' MEM
#MEMSIZE="$MEM""G"
#btrfs filesystem mkswapfile --size $MEMSIZE /swap/swapfile
#echo "/swap/swapfile none swap defaults 0 0" | tee -a /etc/fstab

#  Setup zram

echo "zram" > /etc/modules-load.d/zram.conf
echo "options zram num_devices=1" >> /etc/modules-load.d/zram.conf
echo 'KERNEL=="zram0", ATTR{comp_algorithm}="zstd", ATTR{disksize}="2G" RUN="/usr/bin/mkswap -U clear /dev/zram0", TAG+="systemd"' > /etc/udev/rules.d/99-zram.rules
echo "/dev/zram0     none    swap    sw,pri=100    0 0" >> /etc/fstab

#    Add user

#passwd root
useradd -m bob
passwd bob
#create file bob in /etc/sudoers.d
echo "bob ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/bob

#  copy last step to user directory 'cause we gotta reboot!

sudo -ubob mkdir /home/bob/arch
#mkdir /home/bob/arch
cp --no-preserve=all /root/* /home/bob/arch/

echo -e "\n\nPlease reboot now\n"