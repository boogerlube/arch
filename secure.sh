######
##      fix the disk variable otherwise you are gonna have a bad time!
######

if [[ "$(efivar -d --name 8be4df61-93ca-11d2-aa0d-00e098032b8c-SetupMode)" -ne 1 ]]; then
   echo -e "\nNot in Secure Boot setup mode"
   exit
fi   

export disk="/dev/nvme0n1"
export diskroot="/dev/nvme0n1p2"
export diskboot="/dev/nvme0n1p1"
export sv_opts="rw,noatime,commit=120,compress-force=zstd:1,space_cache=v2"
export rootmnt="/mnt"
USERNAME="bob"

# gotta have whois to use mkpasswd!
pacman -Sy
pacman -S --noconfirm whois

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
  sbctl
  util-linux
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
PASSWORD=$(set_password)
echo -e "\nLUKS Password:"
LUKSPASS=$(set_password)
echo -e "\n"

USERPASSWORD=$(mkpasswd -m sha-512 "$PASSWORD")

# choose hostname
read -p 'Hostname? ' HOST

# Set the time
timedatectl set-ntp true

# Wipe and partition disks
wipefs -af $disk
sgdisk --zap-all --clear $disk
partprobe $disk
sgdisk -n1:0:+512M -t1:ef00 -c1:EFI -N2 -t2:8304 -c2:LINUXROOT $disk
partprobe $disk
mkfs.vfat -F32 -n EFI ${diskboot}

# Setup encryption
echo -n $LUKSPASS | cryptsetup luksFormat --type luks2 ${diskroot}
echo -n $LUKSPASS | cryptsetup open ${diskroot} linuxroot

# Make and mount filesystems setup btrfs subvolumes
mkfs.btrfs -f -L linuxroot /dev/mapper/linuxroot
mount /dev/mapper/linuxroot /mnt
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
mount -o ${sv_opts},subvol=@ /dev/mapper/linuxroot /mnt
mkdir /mnt/efi
mount ${diskboot} /mnt/efi
mount -m -o ${sv_opts},subvol=@home /dev/mapper/linuxroot /mnt/home
mount -m -o ${sv_opts},subvol=@log /dev/mapper/linuxroot /mnt/var/log
mount -m -o ${sv_opts},subvol=@snapshots /dev/mapper/linuxroot /mnt/.snapshots
mount -m -o ${sv_opts},subvol=@swap /dev/mapper/linuxroot /mnt/swap
mount -m -o ${sv_opts},subvol=@cache /dev/mapper/linuxroot /mnt/var/cache
mount -m -o ${sv_opts},subvol=@libvirt /dev/mapper/linuxroot /mnt/var/lib/libvirt
mount -m -o ${sv_opts},subvol=@tmp /dev/mapper/linuxroot /mnt/var/tmp

# Find the best mirrors for installation
reflector -c us -f 20 -l 15 --protocol https --save /etc/pacman.d/mirrorlist

# Finally! Install the base system
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers linux-lts linux-lts-headers util-linux nano dhclient

# For LTS kernel comment out line above and uncomment line below:
#pacstrap -K /mnt base base-devel linux-lts linux-firmware nano dhclient


# Copy the list of mirrors to new system
cp /etc/pacman.d/mirrorlist "$rootmnt"/etc/pacman.d/

# Setup timezone and locale
ln -sf /usr/share/zoneinfo/America/Chicago "$rootmnt"/etc/localtime
arch-chroot "$rootmnt" hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' "$rootmnt"/etc/locale.gen
echo "LANG=en_US.UTF-8" > "$rootmnt"/etc/locale.conf
echo "KEYMAP=us" > "$rootmnt"/etc/vconsole.conf
arch-chroot "$rootmnt" locale-gen

# setup pacman keys
rm -rf "$rootmnt"/etc/pacman.d/gnupg
arch-chroot "$rootmnt" pacman-key --init
arch-chroot "$rootmnt" pacman-key --populate archlinux

#setup kernel cmdline
echo "quiet rw zswap.enabled=0"

#create EFI folder structure
mkdir -p "$rootmnt"/efi/EFI/Linux

#update mkinicpio hooks to change udev to systemd and add encryption
sed -i \
    -e 's/base udev/base systemd/g' \
    -e 's/keymap consolefont/sd-vconsole sd-encrypt/g' \
    "$rootmnt"/etc/mkinitcpio.conf

#update mkinitcpio preset file to generate UKIs
sed -i \
    -e '/^#ALL_config/s/^#//' \
    -e '/^#default_uki/s/^#//' \
    -e '/^#default_options/s/^#//' \
    -e 's/default_image=/#default_image=/g' \
    "$rootmnt"/etc/mkinitcpio.d/linux.preset    

#update mkinitcpio preset for lts kernel
sed -i \
    -e '/^#ALL_config/s/^#//' \
    -e '/^#default_uki/s/^#//' \
    -e '/^#default_options/s/^#//' \
    -e 's/default_image=/#default_image=/g' \
    "$rootmnt"/etc/mkinitcpio.d/linux-lts.preset      

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

# setup services
systemctl --root $rootmnt enable systemd-timesyncd NetworkManager
systemctl --root $rootmnt mask systemd-networkd

# Install systemd-boot
arch-chroot $rootmnt bootctl install --esp-path=/efi

#  Setup zram
echo "zram" > "$rootmnt"/etc/modules-load.d/zram.conf
echo "options zram num_devices=1" >> "$rootmnt"/etc/modules-load.d/zram.conf
echo 'KERNEL=="zram0", ATTR{comp_algorithm}="zstd", ATTR{disksize}="4G" RUN="/usr/bin/mkswap -U clear /dev/zram0", TAG+="systemd"' > "$rootmnt"/etc/udev/rules.d/99-zram.rules
echo "/dev/zram0     none    swap    sw,pri=100    0 0" >> "$rootmnt"/etc/fstab

#  Add user
arch-chroot "$rootmnt" useradd -m -p "$USERPASSWORD" "$USERNAME"

#  create USERNAME file in /etc/sudoers.d
echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> "$rootmnt"/etc/sudoers.d/"$USERNAME"

#  copy last step to user directory 'cause we gotta reboot!
mkdir "$rootmnt"/home/"$USERNAME"/arch
cp * "$rootmnt"/home/"$USERNAME"/arch/
chown -R 1000:1000 "$rootmnt"/home/"$USERNAME"/arch

arch-chroot "$rootmnt" mkinitcpio -p linux

#setup secure boot
arch-chroot "$rootmnt" sbctl create-keys
arch-chroot "$rootmnt" sbctl enroll-keys -m
arch-chroot "$rootmnt" sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
arch-chroot "$rootmnt" sbctl sign -s /efi/EFI/BOOT/BOOTX64.EFI
arch-chroot "$rootmnt" sbctl sign -s /efi/EFI/Linux/arch-linux.efi
arch-chroot "$rootmnt" sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi
arch-chroot "$rootmnt" sbctl sign -s /efi/EFI/Linux/arch-linux-lts.efi
arch-chroot "$rootmnt" sbctl sign -s /efi/EFI/Linux/arch-linux-lts-fallback.efi


umount -R /mnt
echo -e "\n\nPlease reboot now\n"