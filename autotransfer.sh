#!/bin/bash

read -p "Enter the IP address of VPS 2: " VPS2_IP
read -p "Enter the username of VPS 2: " VPS2_USERNAME
read -p "Enter the password of VPS 2: " VPS2_PASSWORD
read -p "Enter the VPS 2 port number for SSH connection (default 22): " VPS2_PORT
echo ""

sshpass -p "$VPS2_PASSWORD" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /usr/local/etc/v2ray/config.json "$VPS2_USERNAME@$VPS2_IP:/usr/local/etc/v2ray/"
sshpass -p "$VPS2_PASSWORD" scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /root/server "$VPS2_USERNAME@$VPS2_IP:/root/"
sshpass -p "$VPS2_PASSWORD" scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /etc/nginx/conf.d "$VPS2_USERNAME@$VPS2_IP:/etc/nginx/"
sshpass -p "$VPS2_PASSWORD" scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /root/cert "$VPS2_USERNAME@$VPS2_IP:/root/"
sshpass -p "$VPS2_PASSWORD" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /lib/systemd/system/web.service "$VPS2_USERNAME@$VPS2_IP:/lib/systemd/system/"

VPS2_PORT=${VPS2_PORT:-22}
sshpass -p "$VPS2_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$VPS2_PORT" "$VPS2_USERNAME@$VPS2_IP" \
"apt update && \
apt install nginx -y && \
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) && \
chmod +x /root/server && \
systemctl enable web.service && \
systemctl start web.service && \
systemctl enable nginx && \
systemctl restart nginx && \
systemctl enable v2ray && \
systemctl restart v2ray && \
apt update && \
apt install git
echo ""
read -p "Do you want to run the hardening script on the VPS 2? Y/N: " answer
if [ "$answer" == "y" ] || [ "$answer" == "Y" ]; then

sshpass -p "$VPS2_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$VPS2_PORT" "$VPS2_USERNAME@$VPS2_IP" << EOF
  sudo apt update
  sudo apt upgrade -y

  sudo apt install fail2ban -y

  sudo adduser --disabled-password --gecos "" lhs

  sudo usermod -aG sudo lhs

  echo "lhs     ALL=(ALL)     NOPASSWD:ALL" | sudo tee -a /etc/sudoers

  su lhs << EOF2
  cd /home/lhs
  mkdir .ssh
  chmod 755 .ssh
  exit
EOF2

  sudo apt install ufw -y
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow OpenSSH
  sudo ufw allow ssh
  sudo ufw allow http
  sudo ufw allow https
  sudo ufw allow 2053
  sudo ufw allow 3000
  read -p "Do you need 56777 port? Y/N: " port_answer
  if [ "$port_answer" == "y" ] || [ "$port_answer" == "Y" ]; then
    ufw allow 56777
  fi
  sudo ufw enable
  sudo ufw reload

  sudo apt install unattended-upgrades -y
  sudo dpkg-reconfigure unattended-upgrades

  sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
  sudo service ssh restart

  echo "Match User root,lhs" >> /etc/ssh/sshd_config
  echo "           PasswordAuthentication no" >> /etc/ssh/sshd_config
  sudo service ssh restart

  sudo apt install apparmor apparmor-utils -y
  sudo aa-enforce /etc/apparmor.d/*

  echo "Welcome to $(hostname)" | sudo tee /etc/issue.net

  mkdir -p /home/lhs/.ssh

  touch /home/lhs/.ssh/authorized_keys

  echo "ssh-rsa 1" joniur@itsjoniur" >> /home/lhs/.ssh/authorized_keys
  echo "ssh-rsa 2" >> /home/lhs/.ssh/authorized_keys
  echo "ssh-rsa 3" >> /home/lhs/.ssh/authorized_keys

  echo "Hardening Done!"
EOF

if [ $? -ne 0 ]; then
  echo "Error: Failed to run the script on the remote server"
else
  echo "Transfer finished!"
fi
