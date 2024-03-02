sv_opts="rw,noatime,commit=120,compress-force=zstd:1,space_cache=v2"
disk="/dev/nvme0n1"
rootmnt="/mnt"

# Make sure disk device exists before beginning
if ! [ -e $disk ] ; then
   echo -ne "\nDevice does not exist!\n"
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

#Open up encrypted root partition
cryptsetup open $diskroot root

# mount all subvols and boot partition
mount -o ${sv_opts},subvol=@ /dev/mapper/root /mnt
mount -m -o noatime,uid=0,gid=0,fmask=0077,dmask=0077 $diskboot /mnt/boot
mount -m -o ${sv_opts},subvol=@home /dev/mapper/root /mnt/home
mount -m -o ${sv_opts},subvol=@log /dev/mapper/root /mnt/var/log
mount -m -o ${sv_opts},subvol=@snapshots /dev/mapper/root /mnt/.snapshots
mount -m -o ${sv_opts},subvol=@swap /dev/mapper/root /mnt/swap
mount -m -o ${sv_opts},subvol=@cache /dev/mapper/root /mnt/var/cache
mount -m -o ${sv_opts},subvol=@libvirt /dev/mapper/root /mnt/var/lib/libvirt
mount -m -o ${sv_opts},subvol=@tmp /dev/mapper/root /mnt/var/tmp

#start chroot to begin repair
# arch-chroot /mnt

# for grub repair use:
# arch-chroot "$rootmnt" grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch

# for systemd boot use:
# bootctl --path="$rootmnt"/boot install