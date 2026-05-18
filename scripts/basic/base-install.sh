#!/usr/bin/bash

USER=$1

apt install sudo apt-transport-https -y

echo -e "\e[<32>BASE-scope apps successfully installed!\e[0m"
echo "Adding new sudoer ($USER)"

echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER
echo -e "\e[<32>New sudoer added (NOPASSWD)\e[0m"

