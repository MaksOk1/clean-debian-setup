#!/usr/bin/env bash

USER=$1

sudo systemctl restart systemd-logind.service
systemctl restart ssh
systemctl restart sshd
cp /etc/zsh/zshrc /root/.zshrc
cp /etc/zsh/zshrc /home/$USER/.zshrc

#sudo update-grub
sudo update-grub2

chsh -s $(which zsh) root
chsh -s $(which zsh) $USER

echo "You can now reboot your machine!"
