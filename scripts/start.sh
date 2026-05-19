#!/usr/bin/env bash
set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_err()     { echo -e "${RED}[ERROR]${NC} $1" >&2; }
die()         { log_err "$1"; exit 1; }

[ "$EUID" -ne 0 ] && die "Please, re-run script as root (sudo)."

detect_os() {
    if [ -f /etc/os-release ]; then
        OS_TYPE=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    
    elif [ -f /etc/debian_version ]; then
        OS_TYPE="debian"
    elif [ -f /etc/redhat-release ]; then
        OS_TYPE="rhel"
    
    elif command -v uname >/dev/null 2>&1; then
        local uname_s
        uname_s=$(uname -s)
        case "$uname_s" in
            Darwin) OS_TYPE="macos" ;;
            FreeBSD) OS_TYPE="freebsd" ;;
            *) OS_TYPE="unknown" ;;
        esac
    else
        OS_TYPE="unknown"
    fi

    OS_TYPE=$(echo "$OS_TYPE" | tr '[:upper:]' '[:lower:]')
    
    readonly OS_TYPE
}

read_secure_password() {
    local prompt_msg=$1
    while true; do
        read -rsp "$prompt_msg" pass1
        echo ""
        read -rsp "Retype password to confirm: " pass2
        echo ""
        if [ "$pass1" = "$pass2" ]; then
            echo "$pass1"
            return 0
        fi
        log_err "Passwords do not match. Try again."
    done
}

detect_os
export AUTO="${AUTO:-0}"


USER="${1:-${ORIGINAL_USER:-${SUDO_USER:-root}}}"
PASSWD=${2:-}

if [ -z "$USER" ] || [ "$USER" = "root" ]; then
    USER="${SUDO_USER:-root}"
fi

MODE_TEXT="${CYAN}INTERACTIVE${NC}"

[ "$AUTO" = "1" ] && MODE_TEXT="${MAGENTA}AUTOMATIC${NC}"

log_info "Detected 'USER' - ($USER)."
log_info "Mode selected - ($MODE_TEXT)."

if [ -n "$USER" ] && [ "$AUTO" = "0" ]; then
    read -rp "[?] Continue for user ($USER)? [Y/n] (or choose other username): " continue_script

	if [[ ! "${continue_script:-Y}" =~ ^[Yy]$ ]]; thens
		USER=""
	fi
fi

if [ -z "$USER" ]; then
	DEFAULT_USER=${SUDO_USER:-root}

    if [ "$AUTO" = "1" ]; then
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

if id "$USER" &>/dev/null || false; then
	echo "Chosen user ($USER) exists. Skipping adding user."

	if [ -n "$PASSWD" ]; then
        if [ "$AUTO" = "1" ]; then
            change_pwd="Y"
        else
            read -rp "Password was given as argument. Change password for existing user ($USER) to it? [y/N]: " change_pwd
            change_pwd=${change_pwd:-N}
        fi
		if [[ ! "$change_pwd" =~ ^[Yy]$ ]]; then
			PASSWD=""
		fi
	else
        if [ "$AUTO" = "1" ]; then
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
            if [ "$AUTO" = "1" ]; then
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

        if echo "$USER:$PASSWD" | chpasswd; then
            echo "Password for user ($USER) updated successfully!"
        else
            echo -e "\e[31m[ERROR]: chpasswd failed. Trying fallback to interactive passwd...\e[0m"
            passwd "$USER"
        fi
    fi
else
	echo "Chosen user ($USER) does not exist on the system."
    if [ "$AUTO" = "1" ]; then
        create_user="Y"
    else
        read -rp "Create user ($USER)? [Y/n]: " create_user
        create_user=${create_user:-Y}
    fi

    if [[ "$create_user" =~ ^[Yy]$ ]]; then
        useradd -m -s /bin/bash "$USER"
        echo "User ($USER) created successfully!"

        if [ "$AUTO" = "1" ]; then
            set_password=$([ -n "$PASSWD" ] && echo "Y" || echo "N")
        else
            read -rp "Set password for user ($USER)? [Y/n]: " set_password
            set_password=${set_password:-Y}
        fi

        if [[ "$set_password" =~ ^[Yy]$ ]]; then
            if [ -n "$PASSWD" ]; then
                if [ "$AUTO" = "1" ]; then
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
                if [ "$AUTO" = "1" ]; then
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

            if echo "$USER:$PASSWD" | chpasswd; then
                echo "Password for user ($USER) set successfully!"
            else
                echo -e "\e[31m[ERROR]: chpasswd failed. Trying fallback to interactive passwd...\e[0m"
                passwd "$USER"
            fi
        fi
    else
        echo "User ($USER) creation skipped. Stopping script."
        exit 0
    fi
fi

URL='https://raw.githubusercontent.com/MaksOk1/clean-debian-setup/main'

# FEATURES rename !
FOLDER_BASE="$(pwd)/scripts"
FOLDER_BASIC="$FOLDER_BASE/basic"
FOLDER_FASTFETCH="$FOLDER_BASE/ssh-fastfetch"
BASH_PATH=$(which bash || command -v bash || echo "/usr/bin/bash") # or '/bin/bash'

# Automatically set 'chmod +x'
echo "Making set-up scripts executable..."
chmod -R +x "$FOLDER_BASE/"
echo -e "\e[32mDone! Executing features set-up...\e[0m"

# Base installation of packages and oh-my-zsh configuration
echo "Set-up of: Basic system feature"
"$BASH_PATH" "$FOLDER_BASIC/base-install.sh" "$USER" "$PASSWD"
"$BASH_PATH" "$FOLDER_BASIC/full-install.sh" "$URL"
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
