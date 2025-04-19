if [ $(id -u) != 0 ] ;
then
  echo -e "\nMust run as root!\n"
  exit
fi

pacman -S docker docker-compose
systemctl enable --now docker.service
usermod -aG docker "$USER"
newgrp docker
