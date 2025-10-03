 [ -z "$PS1" ] && return

if ! [ $(id -u) = 0 ]; then if [ -f /usr/bin/fastfetch ]; then fastfetch; fi fi
