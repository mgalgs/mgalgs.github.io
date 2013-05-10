#!/bin/bash

[[ $# -ne 1 \
    || "$1" == "-h" \
    || "$1" == "--help" \
    || ! -f "$1" ]] && { echo "Usage: $0 draft"; exit 1; }

newfile=_posts/$(date +%Y-%m-%d)-$(basename $1)
mv -vi "$1" "$newfile"
