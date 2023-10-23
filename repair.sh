export sv_opts="rw,noatime,commit=120,compress-force=zstd:1,space_cache=v2"
disk="nvme0n1p"

#Open up encrypted root partition
cryptsetup open /dev/{$disk}2 root

#mount all subvols and boot partition


mount -o ${sv_opts},subvol=@ /dev/mapper/root /mnt
mount -m -o noatime,uid=0,gid=0,fmask=0077,dmask=0077 ${disk}1 /mnt/boot
mount -m -o ${sv_opts},subvol=@home /dev/mapper/root /mnt/home
mount -m -o ${sv_opts},subvol=@log /dev/mapper/root /mnt/var/log
mount -m -o ${sv_opts},subvol=@snapshots /dev/mapper/root /mnt/.snapshots
mount -m -o ${sv_opts},subvol=@swap /dev/mapper/root /mnt/swap
mount -m -o ${sv_opts},subvol=@cache /dev/mapper/root /mnt/var/cache
mount -m -o ${sv_opts},subvol=@libvirt /dev/mapper/root /mnt/var/lib/libvirt
mount -m -o ${sv_opts},subvol=@tmp /dev/mapper/root /mnt/var/tmp

#start chroot to begin repair

arch-chroot /mnt