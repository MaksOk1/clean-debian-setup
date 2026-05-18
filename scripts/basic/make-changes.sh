#!/usr/bin/env bash

USER=$1
URL=$2

sudo curl -s $URL/rs/etc/skel/.zshrc > /etc/skel/.zshrc
sudo curl -s $URL/rs/etc/skel/.zshrc >> /etc/zsh/zshrc
sudo curl -s $URL/rs/etc/systemd/logind.conf >> /etc/systemd/logind.conf
mkdir -v /etc/systemd/sleep.conf.d/
sudo curl -s $URL/rs/etc/systemd/sleep.conf.d/nosuspend.conf > /etc/systemd/sleep.conf.d/nosuspend.conf
sudo curl -s $URL/rs/etc/ssh/sshd_config.d/00-basic.conf > /etc/ssh/sshd_config.d/00-basic.conf

git clone https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh

sudo sed -i 's/GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=2/' /etc/default/grub
