mkinitcpio -P
pacman -S grub grub-btrfs efibootmgr base-devel linux-headers networkmanager network-manager-applet wpa_supplicant dialog os-prober     mtools dosfstools refector git

pacman -S bluez bluez-utils cups xdg-utils xdg-user-dirs btrfs-progs intel-ucode OR amd-ucode
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
blkid -o value /dev/nvme0n1p2 | head -n1 | tee -a /etc/default/grub