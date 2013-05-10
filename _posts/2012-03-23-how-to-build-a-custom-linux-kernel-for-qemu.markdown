---
layout: post
title: How to Build A Custom Linux Kernel For Qemu
tags: [linux, qemu, kernel]
---

<div class="alert-message info">
<b>Update:</b> it's working! No more kernel panic! Big thanks to
Kckanth21 in the comments who helped point me in the right direction
to get this thing working!
<br>
<br>
<b>Update 2:</b> I haven't played with it yet, but <a
href="http://www.landley.net/aboriginal/about.html">Aboriginal
Linux</a> looks like a good way to play around with Linux on qemu... I
would still recommend doing it manually at least once though :)
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

For some reason I had to fix up some includes to get things working
here. Newer versions of busybox might not have this issue, I haven't
really pursued the issue... If you have issues compiling you might
want to apply my patch:

    $ patch -p1 < <(wget https://raw.github.com/gist/3863017/f6d96af7b7cab9346adaf21aa7f05e0cfb722bef/struct_rlimit.diff -q -O-)

Now configure busybox:

    $ make menuconfig

The options I changed were:

* `CONFIG_DESKTOP=n`
* `CONFIG_EXTRA_CFLAGS=-m32 -march=i386` (might not need this if compiling on a 32-bit host)
* `CONFIG_MKFS_EXT2=n`

Compile:

    $ make
    $ make install

Copy the freshly-built busybox system to our initramfs staging area:

    $ sudo cp -avR _install/* ../initramfs/

Now let's have a look at what shared libraries we'll need to include
in our system:

    $ cd ~/linux_qemu/initramfs
    $ ldd bin/busybox
            linux-gate.so.1 =>  (0xf76f7000)
            libm.so.6 => /usr/lib/libm.so.6 (0xf76a1000)
            libc.so.6 => /usr/lib/libc.so.6 (0xf74fe000)
            /lib/ld-linux.so.2 (0xf76f8000)

At this point I did something very hacky and copied over some
libraries from the host machine. This is almost definitely *not* the
right way to do it, but it's working for now so oh well...

    $ mkdir -pv usr/lib
    $ cp -av /usr/lib/lib[mc].so.6 usr/lib/
    $ cp -av /usr/lib/lib[mc]-2.16.so usr/lib/
    $ cp -av /usr/lib/ld-2.16.so usr/lib/
    $ cp -av /lib/ld-linux.so.2 lib/
    $ cp -av /lib/ld-2.16.so lib/

I believe the correct way to do it would be cross-compile `glibc` in a
bootstrapped environment similar to
[how it's done in the `Linux From Scratch`](http://www.linuxfromscratch.org/lfs/view/development/chapter06/glibc.html)
book. It's really kind of tricky to get around the host-library
dependency stuff...

It's also worth mentioning another tool at this point:
[`uclibc`](http://www.uclibc.org/toolchains.html). `uclibc` is a small
C Library targeting embedded systems. It also comes with a very slick
build system called [`buildroot`](http://buildroot.uclibc.org/) that
makes it dead simple to build a full embedded system complete with a
cross-compiled toolchain, root filesystem, kernel image and
bootloader. It basically automates everything we're doing in this
tutorial (and uses a different C Libary). Anyways, it's a very cool
tool, so maybe I'll cover building a qemu system with `uclibc` in
another howto.

### Init

Now we just need to create `/init` which will be called by Linux at
the last stage of the boot process.

    $ emacs ~/linux_qemu/initramfs/init

Here's the contents of my `/init`:

{% highlight bash %}
#!/bin/sh

/bin/mount -t proc none /proc
/bin/mount -t sysfs sysfs /sys

cat <<'EOF'
                       _             _ _                  
 _ __ ___   __ _  __ _| | __ _ ___  | (_)_ __  _   ___  __
| '_ ` _ \ / _` |/ _` | |/ _` / __| | | | '_ \| | | \ \/ /
| | | | | | (_| | (_| | | (_| \__ \ | | | | | | |_| |>  < 
|_| |_| |_|\__, |\__,_|_|\__, |___/ |_|_|_| |_|\__,_/_/\_\
           |___/         |___/                            

EOF
echo 'Enjoy your new system!'

/bin/sh
{% endhighlight %}

Make `/init` executable:

    $ chmod 755 ~/linux_qemu/initramfs/init

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
* `CONFIG_IA32_EMULATION=y` # might not need if on 32-bit host
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
`linux-3.3/arch/x86/boot/`.

## Final Preparations

Now we'll just create a little hard disk to play around with:

    $ cd ~/linux_qemu
    $ qemu-img create disk.img 512M
    $ mkfs.ext2 -F disk.img

## Boot

We can now run our kernel in `qemu`:

    $ qemu-system-i386 -hda disk.img -kernel ../linux-3.3/arch/x86/boot/bzImage -initrd my-initramfs.cpio

Success!

<a href="http://i.imgur.com/iGVfW.png">
<img style="width:600px;" title="Booted into mgalgs linux" src="http://i.imgur.com/iGVfW.png" >
</a>
