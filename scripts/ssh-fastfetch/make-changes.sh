#!/usr/bin/zsh

sudo mv /etc/issue /etc/issue.bak
echo "" > /etc/issue
sudo mv /etc/motd /etc/motd.bak
echo "" > /etc/motd
