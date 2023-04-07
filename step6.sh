grub-mkconfig -o /boot/grub/grub.cfg
chattr +C /swap
read -p 'Swap size in GB? ' MEM
MEMSIZE="$MEM""G"
echo btrfs filesystem mkswapfile --size $MEMSIZE /swap/swapfile
read -p 'press [enter] to continue'
btrfs filesystem mkswapfile --size $MEMSIZE /swap/swapfile
echo "/swap/swapfile none swap defaults 0 0" | tee -a /etc/fstab
#passwd root
useradd -m bob
create file bob in /etc/sudoers.d
echo "bob ALL=(ALL) ALL" >> /etc/sudoers.d/bob