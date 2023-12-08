IFACE="enp3s0"

echo -ne "\n Did you set the interface?"
read yn

# install all required packages.
sudo pacman -S --needed --noconfirm qemu-full virt-manager dnsmasq dmidecode
sudo usermod -aG libvir $USER
sudo systemctl enable --now libvirtd.service


# create a bridge interface. Be sure and set the interface correctly.
sudo nmcli con add type bridge ifname br0 con-name br0
sudo nmcli con add type bridge-slave ifname $IFACE master br0
sudo nmcli con modify br0 bridge.stp no
sudo nmcli con down "Auto Ethernet"
sudo nmcli con up br0