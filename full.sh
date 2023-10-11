######
##      fix the disk variable otherwise you are gonna have a bad time!
######

export disk="/dev/nvme0n1"
export diskroot="/dev/nvme0n1p2"
export diskboot="/dev/nvme0n1p1"
export sv_opts="rw,noatime,commit=120,compress-force=zstd:1,space_cache=v2"
export rootmnt="/mnt"
USERNAME="bob"

# List of packages to install

basepacs=(
  bash-completion
  btrfs-progs
  cryptsetup
  dialog
  dosfstools
  efibootmgr
  git
  iwd
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
  
set_password() {
  local PASSWD1=""
	local PASSWD2=""
  read -p $'\nPlease enter password > ' -rs PASSWD1
	read -p $'\nPlease re-enter password > ' -rs PASSWD2
    if [ "$PASSWD1" != "$PASSWD2" ]; then
        set_password
	else
	    echo "$PASSWD1"
    fi
	
} 
# set passwords
echo -e "\nUser Password:"
USERPASSWORD=$(set_password)
echo -e "\nLUKS Password:"
LUKSPASS=$(set_password)
echo -e "\n"

echo -e "$USERNAME's password: $USERPASSWORD"
echo -e "LUKS password: $LUKSPASS"
read -p "Press any key" KEYPRESS

# choose hostname

read -p 'Hostname? ' HOST

# Set the time

timedatectl set-ntp true

# Wipe and partition disks

wipefs -af $disk
sgdisk --zap-all --clear $disk
partprobe $disk
sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:esp $disk
sgdisk -n 0:0:0 -t 0:8309 -c 0:luks $disk
partprobe $disk
mkfs.vfat -F32 -n ESP ${diskboot}

# Setup encryption

echo -n $LUKSPASS | cryptsetup luksFormat --type luks2 ${diskroot}
echo -n $LUKSPASS | cryptsetup open ${diskroot} root

# Make and mount filesystems setup btrfs subvolumes

mkfs.btrfs -L archlinux /dev/mapper/root
mount /dev/mapper/root /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@snapshots
btrfs su cr /mnt/@log
btrfs su cr /mnt/@swap
btrfs su cr /mnt/@cache
btrfs su cr /mnt/@libvirt
btrfs su cr /mnt/@tmp
umount /mnt

# mount subvolumes

mount -o ${sv_opts},subvol=@ /dev/mapper/root /mnt
mount -m -o noatime,uid=0,gid=0,fmask=0077,dmask=0077 ${diskboot} /mnt/boot
mount -m -o ${sv_opts},subvol=@home /dev/mapper/root /mnt/home
mount -m -o ${sv_opts},subvol=@log /dev/mapper/root /mnt/var/log
mount -m -o ${sv_opts},subvol=@snapshots /dev/mapper/root /mnt/.snapshots
mount -m -o ${sv_opts},subvol=@swap /dev/mapper/root /mnt/swap
mount -m -o ${sv_opts},subvol=@cache /dev/mapper/root /mnt/var/cache
mount -m -o ${sv_opts},subvol=@libvirt /dev/mapper/root /mnt/var/lib/libvirt
mount -m -o ${sv_opts},subvol=@tmp /dev/mapper/root /mnt/var/tmp

# Find the best mirrors for installation

reflector -c us -f 20 -l 15 --protocol https --save /etc/pacman.d/mirrorlist

# Finally! Install the base system

pacstrap -K /mnt base base-devel linux linux-firmware linux-headers nano dhclient

# For LTS kernel comment out line above and uncomment line below:
#pacstrap -K /mnt base base-devel linux-lts linux-firmware nano dhclient

# Create the fstab table and save it

genfstab -U /mnt >> "$rootmnt"/etc/fstab

# Copy the rest of the installer to the new root filesystem

cp /root/arch/* "$rootmnt"/root/
cp /etc/pacman.d/mirrorlist "$rootmnt"/etc/pacman.d/

#Enter the new root filesystem to continue configuration

#umount /mnt/boot
#mount -m -o noatime ${diskboot} /mnt/boot

#echo -e "\n\nplease cd to the /root directory and run step2.sh\n"

#arch-chroot /mnt

# Setup timezone and locale

ln -sf /usr/share/zoneinfo/America/Chicago "$rootmnt"/etc/localtime
arch-chroot "$rootmnt" hwclock --systohc
read -p "Press any key" KEYPRESS
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' "$rootmnt"/etc/locale.gen
arch-chroot "$rootmnt" locale-gen
echo "LANG=en_US.UTF-8" > "$rootmnt"/etc/locale.conf

# setup pacman keys

rm -rf "$rootmnt"/etc/pacman.d/gnupg
arch-root "$rootmnt" pacman-key --init
arch-root "$rootmnt" pacman-key --populate archlinux

# Add encryption to initramfs and setup hostname

sed -i '/^HOOKS=/ s/filesystems/encrypt &/g' "$rootmnt"/etc/mkinitcpio.conf

echo $HOST > "$rootmnt"/etc/hostname
arch-chroot "$rootmnt" mkinitcpio -P

# Setup necessary tools

arch-chroot "$rootmnt" pacman -Sy "${basepacs[@]}" --noconfirm --needed

# Add CPU microcode to system

ucode=$(lscpu | grep "^Vendor ID:" | awk -F":" '{print $2}' | xargs)

if [[ "$ucode" == *"Intel"* ]]; then
  echo "Intel processor detected. Installing intel-ucode...."
  ARCH="intel-ucode.img"
  arch-chroot "$rootmnt" pacman -S --noconfirm intel-ucode
elif [[ "$ucode" == *"AMD"* ]]; then
  echo "AMD processor detected. Installing amd-ucode...."
  ARCH="amd-ucode.img"
  arch-chroot "$rootmnt" pacman -S --noconfirm amd-ucode
else
  echo "No Intel or AMD processor detected."
  ARCH=""
fi

# Install systemd-boot and configure it for encryption

bootctl --path="$rootmnt"/boot install
mkdir "$rootmnt"/boot/loader
mkdir "$rootmnt"/boot/loader/entries
UUID=$(blkid -s UUID -o value ${diskroot})
echo "title Arch Linux" > "$rootmnt"/boot/loader/entries/arch.conf
echo "linux /vmlinuz-linux" >> "$rootmnt"/boot/loader/entries/arch.conf
echo "initrd /"$ARCH >> "$rootmnt"/boot/loader/entries/arch.conf
echo "initrd /initramfs-linux.img" >> "$rootmnt"/boot/loader/entries/arch.conf
# enable zswap
#echo "options cryptdevice=UUID="$UUID":root:allow-discards root=/dev/mapper/root rootflags=subvol=@ rd.luks.options=discard rw" >> "$rootmnt"/boot/loader/entries/arch.conf
# disable zswap
echo "options cryptdevice=UUID="$UUID":root:allow-discards root=/dev/mapper/root rootflags=subvol=@ rd.luks.options=discard rw zswap.enabled=0" >> "$rootmnt"/boot/loader/entries/arch.conf
echo "default  arch.conf" > "$rootmnt"/boot/loader/loader.conf
echo "timeout  4" >> "$rootmnt"/boot/loader/loader.conf
echo "console-mode max" >> "$rootmnt"/boot/loader/loader.conf
echo "editor   no" >> "$rootmnt"/boot/loader/loader.conf


#  Setup swap file

#chattr +C "$rootmnt"/swap
#read -p 'Swap size in GB? ' MEM
#MEMSIZE="$MEM""G"
#btrfs filesystem mkswapfile --size $MEMSIZE "$rootmnt"/swap/swapfile
#echo "/swap/swapfile none swap defaults 0 0" | tee -a "$rootmnt"/etc/fstab

#  Setup zram

echo "zram" > "$rootmnt"/etc/modules-load.d/zram.conf
echo "options zram num_devices=1" >> "$rootmnt"/etc/modules-load.d/zram.conf
echo 'KERNEL=="zram0", ATTR{comp_algorithm}="zstd", ATTR{disksize}="2G" RUN="/usr/bin/mkswap -U clear /dev/zram0", TAG+="systemd"' > "$rootmnt"/etc/udev/rules.d/99-zram.rules
echo "/dev/zram0     none    swap    sw,pri=100    0 0" >> "$rootmnt"/etc/fstab

#    Add user

#passwd root
arch-chroot "$rootmnt" useradd -m -p "$USERPASSWORD" "$USERNAME"
#arch-chroot "$rootmnt" passwd bob
#create file bob in /etc/sudoers.d
echo "bob ALL=(ALL) NOPASSWD: ALL" >> "$rootmnt"/etc/sudoers.d/bob

#  copy last step to user directory 'cause we gotta reboot!

sudo -ubob mkdir "$rootmnt"/home/bob/arch
#mkdir /home/bob/arch
cp * "$rootmnt"/home/bob/arch/
arch-chroot "$rootmnt" chown bob:bob /home/bob/arch/*

echo -e "\n\nPlease exit chroot, unmount the mnt mount and reboot now\n"