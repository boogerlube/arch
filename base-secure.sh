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

# define variables
disk="/dev/nvme0n1"
ENCRYPT=true
rootmnt="/mnt"
USERNAME="bob"
DOMAIN="languy.com"
LTCYAN="\\033[1;96m"
NC="\\033[0m" # no color
TIMEZONE=""
TIMEZONE=$(curl -s http://ip-api.com/line?fields=timezone)
if [[ -z $TIMEZONE ]] ; then
   $TIMEZONE="America/Chicago"
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

# packages to install
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
  sbctl
  sudo
  wpa_supplicant
  xdg-utils
  xdg-user-dirs
  )

if [[ "$(efivar -d --name 8be4df61-93ca-11d2-aa0d-00e098032b8c-SetupMode)" -ne 1 ]]; then
   cecho "RED" "\nNot in Secure Boot setup mode"
   cecho "RED" "Rebooting into firmware setup (press ctrl-c to exit instead)"
   sleep 10
   systemctl reboot --firmware-setup
   exit 1
fi

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

# Make sure disk device exists before beginning
if ! [ -e $disk ] ; then
   cecho "RED" "\nDevice does not exist!"
   lsblk -dpnoNAME | grep -P "/dev/sd|nvme|vd"
   exit 1
fi

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

# set passwords
cecho "CYAN" "\nEnter $USERNAME\'s Password:"
PASSWORD=$(set_password)
if $ENCRYPT ; then
   cecho "CYAN" "Enter \nLUKS Password:"
   LUKSPASS=$(set_password)
fi   
echo -e "\n"
USERPASSWORD=$(mkpasswd -m sha-512 "$PASSWORD")

# choose hostname
echo -n -e "$LTCYAN""Hostname? $NC"
read HOST

# Set the time
timedatectl set-ntp true

# Wipe and partition disks
wipefs -af $disk
sgdisk --zap-all --clear $disk
partprobe $disk
sgdisk -n1:0:+1024M -t1:ef00 -c1:EFI -N2 -t2:8304 -c2:LINUXROOT $disk
partprobe $disk
mkfs.vfat -F32 -n EFI ${diskboot}

 # Setup encryption
MAPPING=${diskroot}
if $ENCRYPT ; then
   echo -n $LUKSPASS | cryptsetup luksFormat --type luks2 ${diskroot}
   echo -n $LUKSPASS | cryptsetup open ${diskroot} root
   MAPPING="/dev/mapper/root"
fi

# Make and mount filesystems
mkfs.ext4 -L linuxroot ${MAPPING}
mount ${MAPPING} /mnt
mkdir /mnt/efi
mount ${diskboot} /mnt/efi

# Find the best mirrors for installation
reflector --verbose -l 25 --sort rate --protocol https --save /etc/pacman.d/mirrorlist

# Finally! Install the base system
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers linux-lts linux-lts-headers util-linux nano dhclient

# Copy the list of mirrors to new system
cp /etc/pacman.d/mirrorlist "$rootmnt"/etc/pacman.d/

# Setup timezone and locale
ln -sf /usr/share/zoneinfo/"$TIMEZONE" "$rootmnt"/etc/localtime
arch-chroot "$rootmnt" hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' "$rootmnt"/etc/locale.gen
echo "LANG=en_US.UTF-8" > "$rootmnt"/etc/locale.conf
echo "KEYMAP=us" > "$rootmnt"/etc/vconsole.conf
arch-chroot "$rootmnt" locale-gen
echo $HOST > "$rootmnt"/etc/hostname

# setup hosts file
cat > "$rootmnt"/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOST.$DOMAIN   $HOST
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

# setup pacman keys
rm -rf "$rootmnt"/etc/pacman.d/gnupg
arch-chroot "$rootmnt" pacman-key --init
arch-chroot "$rootmnt" pacman-key --populate archlinux

#setup kernel cmdline
echo "quiet rw zswap.enabled=0" > "$rootmnt"/etc/kernel/cmdline

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
    -e '/^#fallback_uki/s/^#//' \
    -e '/^#default_options/s/^#//' \
    -e 's/default_image=/#default_image=/g' \
    "$rootmnt"/etc/mkinitcpio.d/linux.preset    

#update mkinitcpio preset for lts kernel
sed -i \
    -e '/^#ALL_config/s/^#//' \
    -e '/^#default_uki/s/^#//' \
    -e '/^#fallback_uki/s/^#//' \
    -e '/^#default_options/s/^#//' \
    -e 's/default_image=/#default_image=/g' \
    "$rootmnt"/etc/mkinitcpio.d/linux-lts.preset      

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
echo "timeout  0" > "$rootmnt"/efi/loader/loader.conf
echo "console-mode max" >> "$rootmnt"/efi/loader/loader.conf
echo "editor   no" >> "$rootmnt"/efi/loader/loader.conf

#  Setup zram
echo "zram" > "$rootmnt"/etc/modules-load.d/zram.conf
echo "options zram num_devices=1" > "$rootmnt"/etc/modprobe.d/zram.conf
echo 'KERNEL=="zram0",ATTR{comp_algorithm}="zstd", ATTR{disksize}="4G" RUN="/usr/bin/mkswap -U clear /dev/zram0", TAG+="systemd"' > "$rootmnt"/etc/udev/rules.d/99-zram.rules
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

#  setup secure boot
arch-chroot "$rootmnt" sbctl create-keys
arch-chroot "$rootmnt" sbctl enroll-keys -m
arch-chroot "$rootmnt" sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
arch-chroot "$rootmnt" sbctl sign -s /efi/EFI/BOOT/BOOTX64.EFI
arch-chroot "$rootmnt" sbctl sign -s /efi/EFI/Linux/arch-linux.efi
arch-chroot "$rootmnt" sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi
arch-chroot "$rootmnt" sbctl sign -s /efi/EFI/Linux/arch-linux-lts.efi
arch-chroot "$rootmnt" sbctl sign -s /efi/EFI/Linux/arch-linux-lts-fallback.efi
arch-chroot "$rootmnt" sbctl sign -s /efi/EFI/systemd/systemd-bootx64.efi

# All done. Unmount everything and reboot.
umount -R /mnt
cecho "GREEN" "\n\nPlease reboot now\n"