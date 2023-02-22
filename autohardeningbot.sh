#!/bin/bash

VPS_IP=""
VPS_USERNAME=""
VPS_PASSWORD=""
VPS_PORT=""

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        IP)
        VPS_IP="$2"
        shift
        shift
        ;;
        USERNAME)
        VPS_USERNAME="$2"
        shift
        shift
        ;;
        PASSWORD)
        VPS_PASSWORD="$2"
        shift
        shift
        ;;
        PORT)
        VPS_PORT="$2"
        shift
        shift
        ;;
        *)
        echo "Error: Invalid argument '$key'. Valid arguments are IP, USERNAME, PASSWORD, and PORT."
        exit 1
        ;;
    esac
done

if [[ -z $VPS_IP || -z $VPS_USERNAME || -z $VPS_PASSWORD || -z $VPS_PORT ]]; then
    echo "Error: Missing one or more required arguments (IP, USERNAME, PASSWORD, or PORT)."
    exit 1
fi


sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$VPS_PORT" "$VPS_USERNAME@$VPS_IP" << EOF
sudo apt update

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
ufw allow $VPS_PORT

sudo ufw --force enable
sudo ufw --force reload

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

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCah7B06XyodjT00Bxde7IR9gcYz2GEremDTzQ0bi9DU3WtykaUiV9oR3xDXJj73RzLldrtt3Rc0XpvnJNRqnPfc6soPBgMhCoiG5Sx18Ivk2bGULJlg5oxcq2SuawjuEZJrRrKMfqhA967c0cpbvlejkk3ycOqm3O8vZNx9fn40gUX9C5jzPWp1KfJyzY+x5m/bNgjXQbKBHlDP3I+AASgF7qNjGUHzoBNN4EGpS0oMYIMdlRnFkzhfkiBWFNxZZJDMVeYWAb7MmLt22HxnVPGw3L0G/tPnQ1XVqwke/bfTunRZLigi/few/Clz0vQS+p+UaZRmQutSh9lAlgGGin3gzheXfbxyzdUA+qFBN056fjJ/tCw9poJYftkFwIspGf5QozeCAdaZ6XynEUZr4PmaJkfGJqIpfvoettIhoHgjingAiLmb74mCoQtugfCHl/t1MsTCto7b1ng84c/JVd5R4zOIzwVM0Fl3SGFrZCLRfHgg4ALBiure/mnDN150AE= joniur@itsjoniur" >> /home/lhs/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCHLxb6MSI1pRDQEo6a2uBOaYB/Ye2wjXyT9OFjFdp3DcZPdwWJ3dag/fpNBTHoscjmMDBVOvqy46f27KdD0CbVLkBAu2fVeP9eQ7xXAPWAhF2J94zrNH7Xs8wxI5b2pfT06OrtYwe/AQnCe9oQdJV5gcS7Hfys0HoiGgQks9tppyZVdCJg0vEpDn0RV6cHZDXhMfmJYp6s/H3ku+KWZtVCE0kBQTkQu8Lb3ITUuGYTBeMWY6XNvPKh1ETlQb/VIV463B/kiDc9Qz3NRQGsXKTbm73DrXXJzak6Q5tq02TZEaqffu5SYLO7xsRY6STNJe+r19hZo6ih9kznGrmrKWdn rsa-key-20230114" >> /home/lhs/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCZcRAEoWP6nBjg/jA4BxxQy7DZm4uqeSGU/e7ujEoI1VzFEcfPK2hUkqGdwoqHU5p6u03PI8eUyMf27qqB/DFV6LejCV6qM3Hr6qX7XmvVfzmQ7ejwdUIOerAZiTBefv7HejK3mXoF3E9QZ++/Ybj46oap0pDz4nmpf2RkTVXamWzALERf9HOoYMpA4NcBSNsvvWgPsJ/8ttf6LZEEVCwzO8aWvmaZUGhoYn75qvD9FHLhLkpkafHSHazBDTrnPjcYdDvwwSnb8pip9mOGjdJ18dARbt6rAnOgvMe1GC5GYM7qm5hx2EcCqbAeS10eTEeYNjsOmBC5ZOPgNTkvbs24n6YsyFcCZNcVDn4buCDjiWshwY5llFQAC2duS4zk+CN0DOBeplSMWpt6VQlPHwFv9sYtiAMPxDCEPLiu+iitpv6goGhNShwbesRfCIYalhv3KycF3Fpsctl6854BgRo/rAXLzSsGPySNi1qIqVaWqcv6U92wITEcF243A0AZ3sc= amir@arcmir" >> /home/lhs/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9Eb73YqMGrNqBheBWn/PGWw7UISnLA1EGc5wjB0FA84GBlAiX/D/MsBYfy1icmR1AYihgc+Eu+Ehetp5M66apCVm5M7Dyixdulzfp0HfESMOScuzvsHTz7FyAZkH1kgcMRU6bC4OA36j13/TG7IXUhCmXl6KpKAnm4s8lse/9LjkrwZjMuL26jpo/q5Nl5JnrUAo9iTJqIJGxLAGXuU7iWiVSz1B94rBndZDjL6pUsQ9USIwj7Q3b3LfD4hPGtQhbBkcLMXqw2b8wqw3jf8joX56Ol37EmGhzRllc+1JRDL0yI9kBjEpYKHuPLL1BHBEEF3nC48uh9V6wpceNcba0/pePB6B+BEuyhYKbEnZSKuL1PTbwDKWwHCWhp7aHPm/8ivKnVkQa+8YPMKucOS3kYa4VmC2OwP49QLQ/zcD0oLedKR3DJXYRT7lopHaR06Lca5yM0IdRM9Q1a2e46m5iVtmgUKSJS2J/ywcALs/Ihy3FpAzy6T79FHt+EI1JeYk= root@srv1675427914.hosttoname.com" >> /home/lhs/.ssh/authorized_keys

echo "Hardening Done!"
EOF
