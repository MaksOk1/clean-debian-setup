#!/usr/bin/bash

if [[ -z "$1" ]]; then
  echo 'Error: USER in $1 is empty. Exiting.'
  exit 1 # Exit with a non-zero status to indicate an error
fi

USER=$1
URL='https://raw.github.com/MaksOk1/clean-debian-setup/main'

# Base installation of packages and oh-my-zsh configuration
$(which bash) ./scripts/base/base-install.sh $USER
$(which bash) ./scripts/base/full-install.sh
$(which bash) ./scripts/base/make-changes.sh $USER $URL
$(which bash) ./scripts/base/finish.sh $USER

# Fastfetch set-up as motd message on login (ssh)
$(which bash) ./scripts/ssh-fastfetch/install.sh
$(which bash) ./scripts/ssh-fastfetch/make-changes.sh $URL
$(which bash) ./scripts/ssh-fastfetch/finish.sh
