#!/usr/bin/zsh

URL=$1

# Fetching needed data for script
sudo curl -s $URL/rs/etc/skel/.zshrc > /etc/skel/.zshrc


# Clearing /etc/motd and /etc/issue
sudo mv /etc/issue /etc/issue__$(date +"%F_%H-%M-%S").bak
echo "" > /etc/issue
sudo mv /etc/motd /etc/motd__$(date +"%F_%H-%M-%S").bak
echo "" > /etc/motd

sudo mv /etc/zsh/zshrc /etc/zsh/zshrc__$(date +"%F_%H-%M-%S").bak
sudo mv /etc/zsh/zshenv /etc/zsh/zshenv__$(date +"%F_%H-%M-%S").bak
