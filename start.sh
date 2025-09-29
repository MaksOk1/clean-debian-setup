#!/usr/bin/bash

if [[ -z "$1" ]]; then
  echo 'Error: USER in $1 is empty. Exiting.'
  exit 1 # Exit with a non-zero status to indicate an error
fi

USER=$1
URL='https://raw.github.com/MaksOk1/clean-debian-setup/main'

$(which bash) ./scripts/base-install.sh $USER
$(which bash) ./scripts/full-install.sh
$(which bash) ./scripts/make-changes.sh $USER $URL
$(which bash) ./scripts/finish.sh $USER

