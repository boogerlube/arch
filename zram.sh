echo "zram" > /etc/modules-load.d/zram.conf
echo "options zram num_devices=1" >> /etc/modules-load.d/zram.conf
echo 'KERNEL=="zram0", ATTR{comp_algorithm}="zstd", ATTR{disksize}="2G" RUN="/usr/bin/mkswap /dev/zram0", TAG+="systemd"' > /etc/udev/rules.d/99-zram.rules

echo "/dev/zram0     none    swap    sw,pri=100    0 0" >> /etc/fstab

