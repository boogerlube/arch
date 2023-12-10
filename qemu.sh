#IFACE="enp3s0"

# get active connection
CONNECTION=$(nmcli -t con show --active | awk -F":" 'NR==1{print $1}')
IFACE=$(nmcli -t con show --active | awk -F":" 'NR==1{print $4}')

echo -ne "\n Interface "$IFACE" is on connection "$CONNECTION".\n"

echo -ne "\nAre the interface and connection correct?"
read yn

# install all required packages.
sudo pacman -S --needed --noconfirm qemu-full virt-manager dnsmasq dmidecode swtpm
sudo usermod -aG libvirt $USER
sudo systemctl enable --now libvirtd.service

# create a bridge interface. Be sure and set the interface correctly.
sudo nmcli con add type bridge ifname br0 con-name br0 stp no
sudo nmcli con add type bridge-slave ifname $IFACE master br0
sudo nmcli con down "$CONNECTION"
sudo nmcli con up br0
sudo nmcli con up bridge-slave-$IFACE
#sudo nmcli con modify br0 bridge.stp no

echo -ne "\nReady to confirm installation?"
read yn

# test qemu installation
sudo virt-host-validate qemu

# use <shift><F12> to release mouse pointer and <shift><F11> to switch full screen mode
# use <L-CTRL><L-ALT> to release mouse as well.
# change br0 interface IP4 settings to 
#            "share with other computers" if using more than 1 nic