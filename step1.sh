######
##      fix the disk variable otherwise you are gonna have a bad time!
######

export disk="/dev/nvme0n1"
export diskpart="/dev/nvme0n1p"

# Set the time

timedatectl set-ntp true

# Wipe and partition disks

wipefs -af $disk
sgdisk --zap-all --clear $disk
partprobe $disk
sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:esp $disk
sgdisk -n 0:0:0 -t 0:8309 -c 0:luks $disk
partprobe $disk
mkfs.vfat -F32 -n ESP ${diskpart}1

# Setup encryption

cryptsetup luksFormat ${diskpart}2
cryptsetup open ${diskpart}2 root

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

# Set your subvolume options here

export sv_opts="rw,noatime,commit=120,compress-force=zstd:1,space_cache=v2"
mount -o ${sv_opts},subvol=@ /dev/mapper/root /mnt
mount -m -o noatime,uid=0,gid=0,fmask=0077,dmask=0077 ${diskpart}1 /mnt/boot
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

genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

# Copy the rest of the installer to the new root filesystem

cp /root/arch/* /mnt/root/
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/

#Enter the new root filesystem to continue configuration

umount /mnt/boot
mount -m -o noatime /dev/nvme0n1p1 /mnt/boot

echo -e ""
echo -e ""
echo "please cd to the /root directory and run step2.sh"
echo -e ""

arch-chroot /mnt
