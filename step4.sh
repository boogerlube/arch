mkinitcpio -P

# edit the following line for your specific CPU type (intel-ucode OR amd-ucode)

pacman -S --noconfirm grub grub-btrfs efibootmgr base-devel linux-headers networkmanager network-manager-applet wpa_supplicant dialog os-prober mtools dosfstools reflector git bluez bluez-utils usbutils cups xdg-utils xdg-user-dirs btrfs-progs

ucode=$(lscpu | grep "^Vendor ID:" | awk -F":" '{print $2}' | xargs)

if [[ "$ucode" == *"Intel"* ]]; then
  echo "Intel processor detected. Installing intel-ucode...."
  pacman -S --noconfirm intel-ucode
elif [[ "$ucode" == *"AMD"* ]]; then
  echo "AMD processor detected. Installing amd-ucode...."
  pacman -S --noconfirm amd-ucode
else
  echo "No Intel or AMD processor detected."
fi

#uncomment amd or intel as necessary for the current machine

#pacman -S amd-ucode
#pacman -S intel-ucode

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
#blkid -o value /dev/nvme0n1p2 | head -n1 | tee -a /etc/default/grub
blkid -o value /dev/nvme0n1p2 | head -n1 > UUID.tmp
UUID=$(cat UUID.tmp)
CMD='cryptdevice=UUID='$UUID':root:allow-discards root=/dev/mapper/root '
echo -e '\n'$CMD | tee -a /etc/default/grub
rm UUID.tmp
echo -e ""
echo -e ""
cat ./step5.txt
echo -e ""