#!/bin/bash

MYEDITOR="emacsclient -n -a emacs"
MYMARKUP=md

usage()
{
    cat <<EOF
usage: $0 [options] title

Options:
  -d    Start a draft

title should be in the following format:

    my-cool-new-post
EOF
}

[[ $# -lt 1 || $1 == "--help" || $1 == "-h" ]] && { usage; exit 1; }

while getopts dh opt; do
    case $opt in
        d) do_draft=yes ;;
        *)
	    usage
	    exit 1
            ;;
    esac
done

shift $(($OPTIND-1))

if [[ "$do_draft" = "yes" ]]; then
    newfile=_drafts/${1}.$MYMARKUP
else
    newfile=_posts/$(date +%Y-%m-%d)-${1}.$MYMARKUP
fi

# start with some bare bones front matter:
cat > $newfile <<EOF
---
layout: post
title:$(for i in $(echo $1 | tr '-' ' '); do echo -n " ${i:0:1}" | tr '[:lower:]' '[:upper:]'; echo -n ${i:1}; done)
tags: [stuff, otherstuff]
---
EOF

$MYEDITOR $newfile
