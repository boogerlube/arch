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
  amd-ucode
  bash-completion
  btrfs-progs
  cryptsetup
  dialog
  dosfstools
  efibootmgr
  fwupd
  git
  inetutils
  intel-ucode
  iwd
  man-db
  mtools
  networkmanager
  network-manager-applet
  os-prober
  pacman-contrib
  reflector
  systemd-ukify
  terminator
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

# Use dhclient to populate /etc/resolv.conf because 
# DNS is getting wiped out during install
dhclient

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

# Wipe and partition disks
wipefs -af $disk
sgdisk --zap-all --clear $disk
partprobe $disk
sgdisk -n 0:0:+1900MiB -t 0:ef00 -c 0:esp $disk
sgdisk -n 0:0:0 -t 0:8309 -c 0:luks $disk
partprobe $disk
mkfs.vfat -F32 -n ESP ${diskboot}
MAPPING=${diskroot}

if $ENCRYPT ; then
   # Setup encryption
   echo -n $LUKSPASS | cryptsetup luksFormat --type luks2 ${diskroot}
   echo -n $LUKSPASS | cryptsetup open ${diskroot} root
   MAPPING="/dev/mapper/root"
fi

# Make and mount filesystems
mkfs.ext4 -L archlinux ${MAPPING}
mount ${MAPPING} /mnt
mount -m -o noatime,uid=0,gid=0,fmask=0077,dmask=0077 ${diskboot} /mnt/boot


# Find the best mirrors for installation
reflector --verbose -f 20 --protocol https --latest 15 --sort rate --country US --save /etc/pacman.d/mirrorlist

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

# Copy the list of mirrors to new system
cp /etc/pacman.d/mirrorlist "$rootmnt"/etc/pacman.d/

# Setup timezone, locale and hostname
ln -sf /usr/share/zoneinfo/"$TIMEZONE" "$rootmnt"/etc/localtime
arch-chroot "$rootmnt" hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' "$rootmnt"/etc/locale.gen
arch-chroot "$rootmnt" locale-gen
echo "LANG=en_US.UTF-8" > "$rootmnt"/etc/locale.conf
echo $HOST > "$rootmnt"/etc/hostname
echo "KEYMAP=us" > "$rootmnt"/etc/vconsole.conf

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

# Add encryption to initramfs
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
  # arch-chroot "$rootmnt" pacman -S --noconfirm intel-ucode
elif [[ "$ucode" == *"AMD"* ]]; then
  echo "AMD processor detected. Installing amd-ucode...."
  ARCH="amd-ucode.img"
  # arch-chroot "$rootmnt" pacman -S --noconfirm amd-ucode
else
  echo "No Intel or AMD processor detected."
  ARCH=""
fi

# Install systemd-boot and configure it for encryption
bootctl --path="$rootmnt"/boot install
mkdir -p "$rootmnt"/boot/loader/entries
UUID=$(blkid -s UUID -o value ${diskroot})
if $LTS ; then
   echo "title Arch Linux" > "$rootmnt"/boot/loader/entries/arch.conf
   echo "linux /vmlinuz-linux-lts" >> "$rootmnt"/boot/loader/entries/arch.conf
   echo "initrd /"$ARCH >> "$rootmnt"/boot/loader/entries/arch.conf
   echo "initrd /initramfs-linux-lts.img" >> "$rootmnt"/boot/loader/entries/arch.conf
else  
   echo "title Arch Linux" > "$rootmnt"/boot/loader/entries/arch.conf
   echo "linux /vmlinuz-linux" >> "$rootmnt"/boot/loader/entries/arch.conf
   echo "initrd /"$ARCH >> "$rootmnt"/boot/loader/entries/arch.conf
   echo "initrd /initramfs-linux.img" >> "$rootmnt"/boot/loader/entries/arch.conf
fi

# enable zswap
#echo "options cryptdevice=UUID="$UUID":root:allow-discards root=${MAPPING} rootflags=subvol=@ rd.luks.options=discard rw" >> "$rootmnt"/boot/loader/entries/arch.conf

# disable zswap
if $ENCRYPT ; then
   echo "options cryptdevice=UUID="$UUID":root:allow-discards root=${MAPPING} rd.luks.options=discard rw zswap.enabled=0 nomodeset" >> "$rootmnt"/boot/loader/entries/arch.conf
else
   echo "options root="$UUID" rw zswap.enabled=0 nomodeset" >> "$rootmnt"/boot/loader/entries/arch.conf
fi   
echo "default  arch.conf" > "$rootmnt"/boot/loader/loader.conf
echo "timeout  0" >> "$rootmnt"/boot/loader/loader.conf
echo "console-mode max" >> "$rootmnt"/boot/loader/loader.conf
echo "editor   yes" >> "$rootmnt"/boot/loader/loader.conf

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

#umount -R /mnt
echo -e "\n\nPlease reboot now\n"