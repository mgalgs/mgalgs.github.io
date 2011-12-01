#!/bin/sh

MYEDITOR="emacsclient -n -a emacs"
MYMARKUP=textile

if [[ $# -ne 1 ]]; then
    echo "usage: $0 title"
    exit 1
fi

newfile=_posts/$(date +%Y-%m-%d)-${1}.$MYMARKUP

# start with some bare bones front matter:
cat > $newfile <<EOF
---
layout: post
title:$(for i in $(echo $1 | tr '-' ' '); do echo -n " ${i:0:1}" | tr '[:lower:]' '[:upper:]'; echo -n ${i:1}; done)
---
EOF

$MYEDITOR $newfile
