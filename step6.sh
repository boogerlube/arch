grub-mkconfig -o /boot/grub/grub.cfg
chattr +C /swap
btrfs filesystem mkswapfile --size <<RAM size>>G /swap/swapfile
echo "/swap/swapfile none swap defaults 0 0" | tee -a /etc/fstab
#passwd root
useradd -m bob
create file bob in /etc/sudoers.d
echo "bob ALL=(ALL) ALL" >> /etc/sudoers.d/bob