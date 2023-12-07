iface="enp3s0"

echo -ne "\n Did you set the interface?"
read yn

# install all required packages.
sudo pacman -S --needed --noconfirm qemu-full virt-manager dnsmasq dmidecode
sudo usermod -aG libvir $user
sudo systemctl enable --now libvirtd.service


# create a bridge interface. Be sure and set the interface correctly.
sudo nmcli con add type bridge ifname br0
sudo nmcli con add type bridge-slave ifname $iface master br0
sudo nmcli con up br0