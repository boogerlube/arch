#Open up encrypted root partition
cryptsetup open /dev/nvme0n1p2 root

#mount all subvols and boot partition

mount -o noatime,subvol=@ /dev/mapper/root /mnt
mount -m -o noatime /dev/nvme0n1p1 /mnt/boot
mount -m -o noatime,subvol=@home /dev/mapper/root /mnt/home
mount -m -o noatime,subvol=@log /dev/mapper/root /mnt/var/log
mount -m -o noatime,subvol=@snapshots /dev/mapper/root /mnt/.snapshots
mount -m -o noatime,subvol=@swap /dev/mapper/luks /mnt/swap

#start chroot to begin repair

arch-chroot /mnt