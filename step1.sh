mkfs.fat -F32 /dev/nvme0n1p1
cryptsetup luksFormat /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 root
mkfs.btrfs /dev/mapper/root
mount /dev/mapper/root /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@snapshots
btrfs su cr /mnt/@log
btrfs su cr /mnt/@swap
umount /mnt
mount -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@ /dev/mapper/root /mnt
mount -m -o noatime /dev/nvme0n1p1 /mnt/boot
mount -m -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@home /dev/mapper/root /mnt/home
mount -m -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@log /dev/mapper/root /mnt/var/log
mount -m -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@snapshots /dev/mapper/root /mnt/.snapshots
mount -m -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@swap /dev/mapper/root /mnt/swap
reflector -c us -f 20 -l 15 --protocol https --save /etc/pacman.d/mirrorlist
pacstrap -K /mnt base base-devel linux linux-firmware nano dhclient
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
cp /root/arch/* /mnt/root/
arch-chroot /mnt
