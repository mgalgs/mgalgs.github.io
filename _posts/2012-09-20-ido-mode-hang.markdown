---
layout: post
title: Ido Mode Hang
tags: [emacs]
---

I ran into a problem the other day where I couldn't get ido-mode to
start up. Every time I would run `M-x ido-mode` emacs would hang up
(even starting with `emacs -Q`)...

The solution turned out to be simple: my `~/.ido.last` file somehow
contained stale references (maybe a network mount that went away or
something), so all I had to do was delete that sucker and I was
`ido`'ing my little heart out once more!
