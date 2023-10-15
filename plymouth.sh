sudo sed -i '/^HOOKS=/ s/autodetect/plymouth &/g' /etc/mkinitcpio.conf
sudo pacman -S plymouth
sudo plymouth-set-default-theme -R spinfinity
#echo "[Daemon] | sudo tee /etc/plymouth/plymouthd.conf
#echo "Theme=spinfinity" | sudo tee -a /etc/plymouth/plymouthd.conf
echo -e "ShowDelay=0" | sudo tee -a /etc/plymouth/plymouthd.conf
echo "DeviceTimeout=5" | sudo tee -a /etc/plymouth/plymouthd.conf
sudo sed -i '/options/ s/$/ splash/' /boot/loader/entries/arch.conf