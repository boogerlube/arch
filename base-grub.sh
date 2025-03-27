#
#      █████╗ ██████╗  ██████╗██╗  ██╗    ███████╗███████╗████████╗██╗   ██╗██████╗ 
#     ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
#     ███████║██████╔╝██║     ███████║    ███████╗█████╗     ██║   ██║   ██║██████╔╝
#     ██╔══██║██╔══██╗██║     ██╔══██║    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ 
#     ██║  ██║██║  ██║╚██████╗██║  ██║    ███████║███████╗   ██║   ╚██████╔╝██║     
#     ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝ 

######
##      fix the disk variable otherwise you are gonna have a bad time!
######

disk="/dev/nvme0n1"
ENCRYPT=true
LTS=false
rootmnt="/mnt"
USERNAME="bob"
DOMAIN="languy.com"
sv_opts="rw,noatime,commit=120,compress-force=zstd:1,space_cache=v2"
LTCYAN="\\033[1;96m"
NC="\\033[0m" # no color


# setup timezones for install
TIMEZONE=""
TIMEZONE=$(curl -s "http://ip-api.com/line?fields=timezone")
if [[ -z $TIMEZONE ]] ; then
   TIMEZONE="America/Chicago"
fi

cecho(){
  RED="\033[1;91m"
  GREEN="\033[1;92m"  
  YELLOW="\033[1;93m" 
  CYAN="\033[1;96m"
	BLUE="\\033[1;94m"
  NC="\033[0m" # No Color

  printf "${!1}${2} ${NC}\n"
}
# List of packages to install
basepacs=(
  bash-completion
  btrfs-progs
  cryptsetup
  dialog
  dosfstools
  efibootmgr
  git
  inetutils
  iwd
  man-db
  mtools
  networkmanager
  network-manager-applet
  os-prober
  pacman-contrib
  reflector
  util-linux
  wpa_supplicant
  xdg-utils
  xdg-user-dirs
  )

# Make sure disk device exists before beginning
if ! [ -e $disk ] ; then
   cecho "RED" "\nDevice does not exist!"
   lsblk -dpnoNAME | grep -P "/dev/sd|nvme|vd"
   exit 1
fi

# Get/set time because Arch will freak if the clock ain't right....
ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
timedatectl set-ntp true
sleep 5
hwclock --systohc

# setup partition vars
disk="${disk,,}"
if [[ $disk == *"nvme"* ]]; then
  diskroot=$disk"p2"
  diskboot=$disk"p1"
else
   diskroot=$disk"2"
   diskboot=$disk"1"
 fi

# gotta have whois to use mkpasswd!
pacman -Sy
pacman -S --noconfirm whois

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
clear
cecho "CYAN" "\nEnter $USERNAME\'s Password:"
PASSWORD=$(set_password)
if $ENCRYPT ; then
   clear
   cecho "CYAN" "Enter \nLUKS Password:"
   LUKSPASS=$(set_password)
fi   
echo -e "\n\n"
USERPASSWORD=$(mkpasswd -m sha-512 "$PASSWORD")

# choose hostname
read -p 'Hostname? ' HOST

# Set the time
timedatectl set-ntp true

# Wipe and partition disks
wipefs -af $disk
sgdisk --zap-all --clear $disk
partprobe $disk
sgdisk -n 0:0:+1024MiB -t 0:ef00 -c 0:esp $disk
sgdisk -n 0:0:0 -t 0:8309 -c 0:luks $disk
partprobe $disk
mkfs.vfat -F32 -n ESP ${diskboot}
MAPPING=${diskroot}

# Setup encryption
if $ENCRYPT ; then
   echo -n $LUKSPASS | cryptsetup luksFormat --type luks2 ${diskroot}
   echo -n $LUKSPASS | cryptsetup open ${diskroot} root
   MAPPING="/dev/mapper/root"
fi

# Make and mount filesystems setup btrfs subvolumes
mkfs.btrfs -f -L archlinux ${MAPPING}
mount ${MAPPING} /mnt
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
mount -o ${sv_opts},subvol=@ ${MAPPING} /mnt
mount -m -o noatime,uid=0,gid=0,fmask=0077,dmask=0077 ${diskboot} /mnt/boot
mount -m -o ${sv_opts},subvol=@home ${MAPPING} /mnt/home
mount -m -o ${sv_opts},subvol=@log ${MAPPING} /mnt/var/log
mount -m -o ${sv_opts},subvol=@snapshots ${MAPPING} /mnt/.snapshots
mount -m -o ${sv_opts},subvol=@swap ${MAPPING} /mnt/swap
mount -m -o ${sv_opts},subvol=@cache ${MAPPING} /mnt/var/cache
mount -m -o ${sv_opts},subvol=@libvirt ${MAPPING} /mnt/var/lib/libvirt
mount -m -o ${sv_opts},subvol=@tmp ${MAPPING} /mnt/var/tmp

# Find the best mirrors for installation
reflector --verbose --age 12 --latest 200 --score 50 --completion-percent 98 --sort rate --save /etc/pacman.d/mirrorlist

# Finally! Install the base system
if $LTS ; then
   # Load LTS kernel
   pacstrap -K /mnt base base-devel linux-lts linux-lts-headers linux-firmware util-linux nano dhclient
else
   # Load standard kernel
   pacstrap -K /mnt base base-devel linux linux-firmware linux-headers util-linux nano dhclient  
fi

# Create the fstab table and save it
genfstab -U /mnt >> "$rootmnt"/etc/fstab

# Copy the rest of the installer to the new root filesystem
cp /root/arch/* "$rootmnt"/root/

# copy the newly generated mirrorlist to the new system.
cp /etc/pacman.d/mirrorlist "$rootmnt"/etc/pacman.d/

# Setup hostname, timezone and locale
ln -sf /usr/share/zoneinfo/America/Chicago "$rootmnt"/etc/localtime
arch-chroot "$rootmnt" hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' "$rootmnt"/etc/locale.gen
arch-chroot "$rootmnt" locale-gen
echo "LANG=en_US.UTF-8" > "$rootmnt"/etc/locale.conf
echo $HOST > "$rootmnt"/etc/hostname

# setup hosts file
cat > "$rootmnt"/etc/hosts <<EOF
127.0.0.1    localhost
::1          localhost
127.0.1.1    $HOST.$DOMAIN   $HOST
ff02::1      ip6-allnodes
ff02::2      ip6-allrouters
EOF

# setup pacman keys
rm -rf "$rootmnt"/etc/pacman.d/gnupg
arch-chroot "$rootmnt" pacman-key --init
arch-chroot "$rootmnt" pacman-key --populate archlinux

# Add encryption to initramfs and setup hostname
sed -i '/^HOOKS=/ s/filesystems/encrypt &/g' "$rootmnt"/etc/mkinitcpio.conf

# create initramfs
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

# Install grub and configure it for encryption
arch-chroot "$rootmnt" grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
UUID=$(blkid -s UUID -o value ${diskroot})

# Choose zswap disabled.
CMD='cryptdevice=UUID='$UUID':root:allow-discards root=/dev/mapper/root zswap.enabled=0'

# Choose zswap enabled.
#CMD='cryptdevice=UUID='$UUID':root:allow-discards root=/dev/mapper/root'

sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s|loglevel=3|$CMD &|g" "$rootmnt"/etc/default/grub
arch-chroot "$rootmnt" grub-mkconfig -o /boot/grub/grub.cfg


#  Setup swap file
#chattr +C "$rootmnt"/swap
#read -p 'Swap size in GB? ' MEM
#MEMSIZE="$MEM""G"
#btrfs filesystem mkswapfile --size $MEMSIZE "$rootmnt"/swap/swapfile
#echo "/swap/swapfile none swap defaults 0 0" | tee -a "$rootmnt"/etc/fstab

#  Setup zram
echo "zram" > "$rootmnt"/etc/modules-load.d/zram.conf
echo "options zram num_devices=1" > "$rootmnt"/etc/modprobe.d/zram.conf
echo 'KERNEL=="zram0",ATTR{comp_algorithm}="zstd", ATTR{disksize}="4G" RUN="/usr/bin/mkswap -U clear /dev/zram0", TAG+="systemd"' > "$rootmnt"/etc/udev/rules.d/99-zram.rules
echo "/dev/zram0     none    swap    sw,pri=100    0 0" >> "$rootmnt"/etc/fstab

#  Add user
arch-chroot "$rootmnt" useradd -m -p "$USERPASSWORD" "$USERNAME"

#  create USERNAME file in /etc/sudoers.d
echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> "$rootmnt"/etc/sudoers.d/"$USERNAME"

# Setup services
systemctl --root $rootmnt enable systemd-timesyncd NetworkManager
systemctl --root $rootmnt mask systemd-networkd

#  copy last step to user directory 'cause we gotta reboot!
mkdir "$rootmnt"/home/"$USERNAME"/arch
cp * "$rootmnt"/home/"$USERNAME"/arch/
chown -R 1000:1000 "$rootmnt"/home/"$USERNAME"/arch

umount -R /mnt
echo -e "\n\nPlease reboot now\n"