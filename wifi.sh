rfkill unblock all
iwctl device list
iwctl station wlan0 get-networks
iwctl station wlan0 connect UCanHazWiFi
sleep 5
iwctl station wlan0 show


