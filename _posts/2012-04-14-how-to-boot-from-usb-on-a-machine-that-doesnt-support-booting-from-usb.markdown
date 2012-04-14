---
layout: post
title: How To Boot From USB On A Machine That Doesn't Support Booting From USB
tags: [linux, grub, bootloader]
---

How do you boot from a USB stick on a machine that doesn't support
booting from USB sticks? The answer, of course, is that you cheat. You
install grub on a hard disk on the machine and then you `chainload`
the bootloader on the USB stick. Here's how you do it in grub 0.97:

    grub> root (hd1,1)
    grub> makeactive
    grub> chainloader +1

**TIP**: make liberal use of your TAB key when trying to figure out
  where the boot disk/partition are located during the `root` command.

See
[this](http://www.gnu.org/software/grub/manual/legacy/grub.html#Chain_002dloading)
section in the grub manual for more information on chain-loading in grub 0.97.

You can also just boot the kernel directly from the USB stick rather
than chain-loading to the bootloader on the USB stick, as long as you
know what kernel, initrd, etc you want to load.
