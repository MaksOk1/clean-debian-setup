#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease, re-run script as root (sudo).\e[0m"
    exit 1
fi

if [ "${1:-}" = "-y" ]; then
    # make run AUTO=1
    make run ARGS="-y"
else
    make run
fi