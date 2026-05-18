#!/usr/bin/env bash

if [[ -z "$1" ]]; then
  echo 'Error: USER in $1 is empty. Exiting.'
  exit 1 # Exit with a non-zero status to indicate an error
fi

USER=$1
URL='https://raw.github.com/MaksOk1/clean-debian-setup/main'
# FEATURES rename !
FOLDER_BASIC='./scripts/basic'
FOLDER_FASTFETCH='./scripts/ssh-fastfetch'

# Base installation of packages and oh-my-zsh configuration
$(which bash) "$FOLDER_BASIC/base-install.sh" $USER
$(which bash) "$FOLDER_BASIC/full-install.sh"
$(which bash) "$FOLDER_BASIC/make-changes.sh" $USER $URL
$(which bash) "$FOLDER_BASIC/finish.sh" $USER

# Fastfetch set-up as motd message on login (ssh)
$(which bash) "$FOLDER_FASTFETCH/install.sh"
$(which bash) "$FOLDER_FASTFETCH/make-changes.sh" $URL
$(which bash) "$FOLDER_FASTFETCH/finish.sh"
