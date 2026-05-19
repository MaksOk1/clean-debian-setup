#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease, re-run script as root (sudo).\e[0m"
    exit 1
fi

if [ -n "${1:-}" ]; then
    USER=$1
else
	USER="${ORIGINAL_USER:-${SUDO_USER:-root}}"
fi
PASSWD=${2:-}
export AUTO="${AUTO:-0}"
IS_AUTO="$AUTO"

if [ "$IS_AUTO" = "1" ]; then
    MODE_TEXT="\e[35mAUTOMATIC\e[32m"
else
    MODE_TEXT="\e[36mINTERACTIVE\e[32m"
fi

echo -e "\e[32mDetected 'USER' - ($USER).\e[0m"
echo -e "\e[32mMode selected - ($MODE_TEXT).\e[0m"
if [ -n "$USER" ]; then
    if [ "$IS_AUTO" = "1" ]; then
		continue_script="Y"
    else
        read -rp "Continue for user ($USER)? [Y/n] (or choose other username): " continue_script
        continue_script=${continue_script:-Y}
    fi

	if [[ "$continue_script" =~ ^[Yy]$ ]]; then
		echo -e "\e[32mContinuing with user: $USER!\e[0m"
	else
		USER=""
	fi
fi

if [ -z "$USER" ]; then
	DEFAULT_USER=${SUDO_USER:-root}

    if [ "$IS_AUTO" = "1" ]; then
		USER=$DEFAULT_USER
    else
        while true; do
            read -rp "Enter username of user you want to configure [default: $DEFAULT_USER]: " INPUT_USER
            INPUT_USER=${INPUT_USER:-$DEFAULT_USER}

            if [ -n "$INPUT_USER" ]; then
                USER=$INPUT_USER
                break
            fi

            echo -e "\e[31mPlease enter a valid username (or set 'USER' variable) to continue.\e[0m"
        done
    fi
fi

if id "$USER" &>/dev/null; then
	echo "Chosen user ($USER) exists. Skipping adding user."

	if [ -n "$PASSWD" ]; then
        if [ "$IS_AUTO" = "1" ]; then
            change_pwd="Y"
        else
            read -rp "Password was given as argument. Change password for existing user ($USER) to it? [y/N]: " change_pwd
            change_pwd=${change_pwd:-N}
        fi
		if [[ ! "$change_pwd" =~ ^[Yy]$ ]]; then
			PASSWD=""
		fi
	else
        if [ "$IS_AUTO" = "1" ]; then
            change_pwd="N"
        else
            read -rp "Do you want to change password for existing user ($USER)? [y/N]: " change_pwd
            change_pwd=${change_pwd:-N}
        fi
        if [[ ! "$change_pwd" =~ ^[Yy]$ ]]; then
            echo "Password change skipped."
        fi
	fi
	
	if [[ "${change_pwd:-N}" =~ ^[Yy]$ ]]; then
        if [ -z "$PASSWD" ]; then
            if [ "$IS_AUTO" = "1" ]; then
                echo -e "\e[31mError: Password change requested in AUTO mode but no password provided.\e[0m"
                exit 1
            fi

            while true; do
                read -rsp "Enter NEW password for user ($USER): " PASSWD
                echo ""
                read -rsp "Retype new password: " PASSWD_CONFIRM
                echo ""

                if [ "$PASSWD" = "$PASSWD_CONFIRM" ]; then
                    break
                else
                    echo -e "\e[31mPasswords do not match. Try again.\e[0m"
                fi
            done
        fi

        echo "$USER:$PASSWD" | chpasswd
        echo "Password for user ($USER) updated successfully!"
    fi
else
	echo "Chosen user ($USER) does not exist on the system."
    if [ "$IS_AUTO" = "1" ]; then
        create_user="Y"
    else
        read -rp "Create user ($USER)? [Y/n]: " create_user
        create_user=${create_user:-Y}
    fi

    if [[ "$create_user" =~ ^[Yy]$ ]]; then
        useradd -m -s /bin/bash "$USER"
        echo "User ($USER) created successfully!"

        if [ "$IS_AUTO" = "1" ]; then
            set_password=$([ -n "$PASSWD" ] && echo "Y" || echo "N")
        else
            read -rp "Set password for user ($USER)? [Y/n]: " set_password
            set_password=${set_password:-Y}
        fi

        if [[ "$set_password" =~ ^[Yy]$ ]]; then
            if [ -n "$PASSWD" ]; then
                if [ "$IS_AUTO" = "1" ]; then
                    use_arg_password="Y"
                else
                    read -rp "Password was given as argument. Use it for new user? [Y/n]: " use_arg_password
                    use_arg_password=${use_arg_password:-Y}
                fi

                if [[ ! "$use_arg_password" =~ ^[Yy]$ ]]; then
                    PASSWD=""
                fi
            fi

            if [ -z "$PASSWD" ]; then
                if [ "$IS_AUTO" = "1" ]; then
                    echo -e "\e[31mError: Cannot set empty password for new user in AUTO mode.\e[0m"
                    exit 1
                fi
                while true; do
                    read -rsp "Enter password for new user ($USER): " PASSWD
                    echo ""
                    read -rsp "Retype password: " PASSWD_CONFIRM
                    echo ""

                    if [ "$PASSWD" = "$PASSWD_CONFIRM" ]; then
                        break
                    else
                        echo -e "\e[31mPasswords do not match. Try again.\e[0m"
                    fi
                done
            fi

            echo "$USER:$PASSWD" | chpasswd
            echo "Password for user ($USER) set successfully!"
        fi
    else
        echo "User ($USER) creation skipped. Stopping script."
        exit 0
    fi
fi

URL='https://raw.github.com/MaksOk1/clean-debian-setup/main'

# FEATURES rename !
FOLDER_BASE='./scripts'
FOLDER_BASIC="$FOLDER_BASE/basic"
FOLDER_FASTFETCH="$FOLDER_BASE/ssh-fastfetch"
BASH_PATH=$(which bash || command -v bash || echo "/usr/bin/bash") # or '/bin/bash'

# Automatically set 'chmod +x'
echo "Making set-up scripts executable..."
chmod -R +x "$FOLDER_BASE"
echo -e "\e[32mDone! Executing features set-up...\e[0m"

# Base installation of packages and oh-my-zsh configuration
echo "Set-up of: Basic system feature"
"$BASH_PATH" "$FOLDER_BASIC/base-install.sh" "$USER" "$PASSWD"
"$BASH_PATH" "$FOLDER_BASIC/full-install.sh"
"$BASH_PATH" "$FOLDER_BASIC/make-changes.sh" "$USER" "$URL"
"$BASH_PATH" "$FOLDER_BASIC/finish.sh" "$USER"
echo -e "\e[32mSetted-up: Basic system feature!\e[0m"

# Fastfetch set-up as motd message on login (ssh)
echo "Set-up of: Fastfetch feature"
"$BASH_PATH" "$FOLDER_FASTFETCH/install.sh"
"$BASH_PATH" "$FOLDER_FASTFETCH/make-changes.sh" "$URL"
"$BASH_PATH" "$FOLDER_FASTFETCH/finish.sh"
echo -e "\e[32mSetted-up: Fastfetch feature!\e[0m"

# Clean-up
echo -e "\e[32mAll features setted up! Cleaning...\e[0m"
"$BASH_PATH" "$FOLDER_BASE/cleanup.sh"
echo -e "\e[32mClean-up completed!\e[0m"

echo -e "\e[32mNow it is recommended to reboot the machine!\nAll done!\e[0m"
