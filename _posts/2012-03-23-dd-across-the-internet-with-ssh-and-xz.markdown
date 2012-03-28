---
layout: post
title: dd Across The Internet With ssh and xz
tags: [linux, dd, xz, ssh, command-line]
---

Here's how you can back up an entire hard disk across the internet
(compressed with `pv` to save as much bandwidth as possible):

    $ ssh -p 2222 root@sonzona.dyndns.org 'dd if=/dev/xvda1 | xz -c' | pv > sonzonaroot.img.xz

To view your files on the other end:

    $ xz -d sonzonaroot.img.xz
    # mkdir /mnt/disk
    # mount -o loop sonzonaroot.img /mnt/disk

You can always *not* `xz` the image up if you happen to be limited by
CPU or RAM, rather than bandwidth.

Happy `dd`'ing!
