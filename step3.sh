mkinitcpio -P

# edit the following line for your specific CPU type (intel-ucode OR amd-ucode)

pacman -S --noconfirm grub grub-btrfs efibootmgr base-devel linux-headers networkmanager network-manager-applet wpa_supplicant dialog os-prober mtools dosfstools reflector git bluez bluez-utils cups xdg-utils xdg-user-dirs btrfs-progs intel-ucode

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
blkid -o value /dev/nvme0n1p2 | head -n1 | tee -a /etc/default/grub