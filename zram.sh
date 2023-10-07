########################################################################################
###                                                                                  ###
###                                     IMPORTANT                                    ###
###                                                                                  ###
###  Please disable zswap by adding "zswap.enabled=0" to your kernel parameters.     ###
###  If'n you don't bad things will happen.                                          ###
###                                                                                  ###
###  If using grub, edit /etc/default/grub. Add zswap.enabled=0 to the end of:       ###
###        GRUB_CMDLINE_LINUX_DEFAULT                                                ###
###  Be sure and run sudo grub-mkconfig -o /boot/grub/grub.cfg after                 ###
###                                                                                  ###
###  If using systemd-boot, edit your entry in /boot/loader/entries.                 ### 
###  Add zswap.enabled=0 to the options line of arch.conf.                           ###
########################################################################################

# make sure we run as root 

if [ $(id -u) != 0 ]; 
then
   echo "Must run as root" 
   exit
fi

echo "zram" > /etc/modules-load.d/zram.conf
echo "options zram num_devices=1" >> /etc/modules-load.d/zram.conf
echo 'KERNEL=="zram0", ATTR{comp_algorithm}="zstd", ATTR{disksize}="2G" RUN="/usr/bin/mkswap -U clear /dev/zram0", TAG+="systemd"' > /etc/udev/rules.d/99-zram.rules
echo "/dev/zram0     none    swap    sw,pri=100    0 0" >> /etc/fstab

echo -e "\n\nPlease reboot now\n"

