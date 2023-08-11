ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
rm -rf /etc/pacman.d/gnupg
pacman-key --init
pacman-key --populate archlinux
echo -e ""
echo -e ""
cat step3.txt
echo -e ""
