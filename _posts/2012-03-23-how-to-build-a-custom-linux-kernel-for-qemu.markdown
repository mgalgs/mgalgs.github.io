---
layout: post
title: How to Build A Custom Linux Kernel For Qemu
tags: [linux, qemu, kernel, workinprogress]
---

In this howto, we're going to build a Linux system from the ground up
using kernel sources from kernel.org and a busybox-based `initramfs`,
which we will then run under `qemu`.

## Initial Ramdisk

Linux needs something called the *initial ramdisk* in order to
complete its boot process. The initial ramdisk is a filesystem image
that is mounted temporarily at `/` while the Linux boots. The purpose
of the initial ramdisk is to provide kernel modules and necessary
utilities that might be needed in order to bring up the *real* root
filesystem.

As outlined in
[the initrd Wikipedia article](http://en.wikipedia.org/wiki/Initrd),
there are currently two approaches that fulfill the role of the
initial ramdisk: *initrd* and *initramfs*. We'll be using the
`initramfs` approach.

The gentoo-wiki has a great
[article](http://en.gentoo-wiki.com/wiki/Initramfs) about
initramfs. We'll be following that article closely here.

First, create some directory structure for our `initramfs`:

    $ mkdir initramfs
    $ cd initramfs/
    $ mkdir -pv bin lib dev etc mnt/root proc root sbin sys
    $ sudo cp -va /dev/{null,console,tty} dev/

Now we need some stuff to put in our initial ramdisk. We'll be using
`busybox` since it provides a multitude of useful utilities all in a
single binary.

### Building BusyBox

Now we'll compile busybox:

    $ cd ../../somewhere_else
    $ wget http://busybox.net/downloads/busybox-1.19.4.tar.bz2
    $ tar xf busybox-1.19.4.tar.bz2
    $ cd busybox-1.19.4/
    $ make menuconfig

The only option I changed was `CONFIG_DESKTOP=n`.

    $ make
    $ cp -av busybox /path/to/initramfs/bin/

Since we really want a minimal system, we could have also built a
[`uclibc` toolchain](http://www.uclibc.org/toolchains.html). uclibc
provides an excellent framework for building entire systems (including
busybox and the Linux kernel). Maybe I'll cover building a `uclibc`
toolchain in another howto.

### Init

Now we just need to create `/init` which will be called by Linux at
the last stage of the boot process.

Here's the contents of my `/init`:

    stuff

We should now have everything necessary for our `initramfs`. We will
`cpio` it up:

    find . -print0 | cpio --null -ov --format=newc > my-initramfs.cpio

We avoid `gzip`'ing it here because the emulator takes forever to
unpack it if we do...

If you want to see how to build a tiny Linux system from scratch using
the *initrd* method, you can refer to
[this](http://free-electrons.com/docs/elfs/) awesome presentation.

## Kernel Configuration

    $ wget http://www.kernel.org/pub/linux/kernel/v3.x/linux-3.3.tar.xz
    $ tar xf linux-3.3.tar.xz
    $ cd linux-3.3/

We'll start with a minimal configuration, then add only what we need:

    $ make allnoconfig
    $ make menuconfig

I added:

* `CONFIG_BLK_DEV_INITRD=y`
* `CONFIG_PARAVIRT_GUEST=y`
* `CONFIG_XEN=y`
* `CONFIG_PCI=y`
* `CONFIG_IA32_EMULATION=y`
* `CONFIG_NET=y`
* `CONFIG_INET=y`
* `CONFIG_ATA=y`
* `CONFIG_NETDEVICES=y`
* `CONFIG_NET_VENDOR_REALTEK=y`
* `CONFIG_8139TOO=y` (unchecked all other Ethernet drivers)
* `CONFIG_LAN=n`

You can see my entire kernel `.config` [here](http://sprunge.us/LiKV).

Now we're ready to build the kernel:

    $ make

Our kernel image should now be available at
`.../linux-3.3/arch/x86/boot/`.

## Final Preparations

Now we'll just create a little hard disk to play around with:

    $ qemu-img create disk.img 512M
    $ mkfs.ext2 -F disk.img

## Boot

We can now run our kernel in `qemu`:

    $ qemu-system-x86_64 -hda disk.img -kernel ../linux-3.3/arch/x86/boot/bzImage -initrd my-initramfs.cpio

