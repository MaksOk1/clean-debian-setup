#!/usr/bin/env bash
if [ "${1:-}" = "-y" ]; then
    make run AUTO=1
else
    make run
fi