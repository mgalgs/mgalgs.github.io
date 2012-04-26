---
layout: post
title: How to Build A Custom Linux Kernel For Qemu
tags: [linux, qemu, kernel, workinprogress]
---

<div class="alert-message info">

<b>Note</b>: This post is still a work-in-progress. My kernel
currently panics while trying to execute <code>/init</code> :(.

 </div>

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

We'll be creating everything under `~/linux_qemu`:

    $ mkdir ~/linux_qemu
    $ cd ~/linux_qemu

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

    $ cd ~/linux_qemu
    $ wget http://busybox.net/downloads/busybox-1.19.4.tar.bz2
    $ tar xf busybox-1.19.4.tar.bz2
    $ cd busybox-1.19.4/
    $ make menuconfig

The options I changed were:

* `CONFIG_DESKTOP=n`
* `CONFIG_EXTRA_CFLAGS=-m32 -march=i386` (because I'm compiling on a 64-bit host)
* `CONFIG_MKFS_EXT2=n`


    $ make
    $ LDFLAGS="--verbose -m32" make
    $ cp -av busybox ~/linux_qemu/initramfs/bin/

Double check that the shared libraries look sane:

    $ ldd busybox
            linux-gate.so.1 =>  (0xf76f7000)
            libm.so.6 => /usr/lib32/libm.so.6 (0xf76a1000)
            libc.so.6 => /usr/lib32/libc.so.6 (0xf74fe000)
            /lib/ld-linux.so.2 (0xf76f8000)
    

    $ cp -av busybox ~/linux_qemu/initramfs/bin/
    $ cp -av /usr/lib32/lib[mc].so.6 ~/linux_qemu/initramfs/lib/
    OR
    $ cp -av /usr/lib32/lib[cm]-2.15.so lib/



Since we really want a minimal system, we could have also built a
[`uclibc` toolchain](http://www.uclibc.org/toolchains.html). uclibc
provides an excellent framework for building entire systems (including
busybox and the Linux kernel). Maybe I'll cover building a `uclibc`
toolchain in another howto.

### Init

Now we just need to create `/init` which will be called by Linux at
the last stage of the boot process.

    $ emacs ~/linux_qemu/initramfs/init

Here's the contents of my `/init`:

{% highlight bash %}
#!/bin/bash

echo "stuff"
# todo finish setting up busybox and launch a shell
{% endhighlight %}

You might notice that that looks pretty lame :). As mentioned at the
top of this post, my kernel panics at `/init`. I've tried compiling a
minimal C program but that's not working either... As soon as I can
run `echo` or `printf` I'll finish my `/init` script :).

We should now have everything necessary for our `initramfs`. We will
`cpio` it up:

    $ cd ~/linux_qemu/initramfs
    $ find . -print0 | cpio --null -ov --format=newc > ../my-initramfs.cpio

We avoid `gzip`'ing it here because the emulator takes forever to
unpack it if we do...

If you want to see how to build a tiny Linux system from scratch using
the *initrd* method, you can refer to
[this](http://free-electrons.com/docs/elfs/) awesome presentation.

## Kernel Configuration

    $ cd ~/linux_qemu
    $ wget http://www.kernel.org/pub/linux/kernel/v3.x/linux-3.3.tar.xz
    $ tar xf linux-3.3.tar.xz
    $ cd linux-3.3/

We'll start with a minimal configuration, then add only what we need:

    $ make allnoconfig
    $ make menuconfig

I added:

* `CONFIG_BLK_DEV_INITRD=y`
* `CONFIG_INITRAMFS_SOURCE=/home/mgalgs/linux_qemu/initramfs`
* `CONFIG_PCI=y`
* `CONFIG_BINFMT_ELF=y`
* `CONFIG_SERIAL_8250`
* `CONFIG_EXT2_FS=y`
* `CONFIG_IA32_EMULATION=y`
* `CONFIG_NET=y`
* `CONFIG_PACKET=y`
* `CONFIG_UNIX=y`
* `CONFIG_INET=y`
* `CONFIG_WIRELESS=n`
* `CONFIG_ATA=y`
* `CONFIG_NETDEVICES=y`
* `CONFIG_NET_VENDOR_REALTEK=y`
* `CONFIG_8139TOO=y` (unchecked all other Ethernet drivers)
* `CONFIG_WLAN=n`

* `CONFIG_DEVTMPFS=y`

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

