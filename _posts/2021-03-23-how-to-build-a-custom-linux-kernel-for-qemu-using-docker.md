---
layout: post
title: How To Build A Custom Linux Kernel For Qemu Using Docker
tags: [linux, qemu, kernel, docker]
---

This is an updated version of my
[Linux Kernel/Qemu tutorial from 2015]({% post_url 2015-05-16-how-to-build-a-custom-linux-kernel-for-qemu-2015-edition %}).

That tutorial is still useful, but as build requirements have evolved over
the years it turned into missing-package-whack-a-mole, with each distro
requiring different packages to get things building.

By using `docker`, we can create a fully reproducible and consistent build
environment that works the exact same way on any system that runs
`docker`. I've tested these instructions on Debian, Arch, Ubuntu, and Mac
OSX. If you're using OSX just make sure your building on a case sensitive
filesystem.

Note that we're still going to run our custom kernel using `qemu` directly
on the host system, we're just using `docker` for the build.

So let's dive in!

# Preparation

## Source Preparation

First, create a workspace:

    $ TOP=$HOME/teeny-linux
    $ mkdir -pv $TOP

Our entire system will be composed of exactly two packages: the Linux
kernel and Busybox. Download and extract them now:

    $ cd $TOP
    $ curl https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.11.7.tar.xz | tar xJf -
    $ curl https://busybox.net/downloads/busybox-1.32.1.tar.bz2 | tar xjf -

## Build Environment

Now we'll create our `docker` image.

    $ mkdir -pv docker
    $ cd docker

Then create a `Dockerfile` at `$TOP/docker/Dockerfile` with the following
content:

```
FROM debian:10.8-slim

RUN apt-get update
RUN apt-get install -y \
        bc \
        bison \
        build-essential \
        cpio \
        flex \
        libelf-dev \
        libncurses-dev \
        libssl-dev \
        vim-tiny
```

And build the `docker` image (add `sudo` if necessary on your system):

    $ docker build . -t teeny-linux-builder

For simplicity we'll be running as `root` in the docker container. If you
really want to build as a regular user within your container you can always
do something like
[this](https://faun.pub/set-current-host-user-for-docker-container-4e521cef9ffc).

# Busybox Userland

The first thing we'll do is create a minimal userland based on the
ever-useful `busybox` tool.  After building `busybox`, we'll throw it in a
minimal filesystem hierarchy and package it up in an
[`initramfs`](http://en.wikipedia.org/wiki/Initramfs) using `cpio`.

Let's go configure `busybox` now.

First we enter our build container:

    $ docker run -ti -v $TOP:/teeny teeny-linux-builder

and prepare the initial `busybox` configuration:

    # cd /teeny/busybox-1.32.1
    # mkdir -pv ../obj/busybox-x86
    # make O=../obj/busybox-x86 defconfig

(Note: in the `busybox` build system, `O=` means "place build output here".
This allows you to host multiple different configurations out of the same
source tree.  The Linux kernel follows a similar convention.)

This gives us a basic starting point.  We're going to take the easy way out
here and just statically link `busybox` in order to avoid fiddling with
shared libraries.  We'll need to use `busybox`'s `menuconfig` interface to
enable static linking:

    # make O=../obj/busybox-x86 menuconfig

type `/`, search for "static".  You'll see that the option is located at:

    -> Settings
    [ ] Build static binary (no shared libs)

Go to that location, select it by pressing `space`, and exit (saving
changes).

Now build `busybox`:

    # cd ../obj/busybox-x86
    # make -j$(nproc)
    # make install

(The `-j$(nproc)` causes `make` to execute a concurrent build using the
same number of build process as you have processor cores.)

So far so good.  With a statically-linked `busybox` in hand we can build
the directory structure for our `initramfs`:

    # mkdir -pv /teeny/initramfs/x86-busybox
    # cd /teeny/initramfs/x86-busybox
    # mkdir -pv {bin,sbin,etc,proc,sys,usr/{bin,sbin}}
    # cp -av /teeny/obj/busybox-x86/_install/* .

Of course, there's a lot missing from this skeleton hierarachy that will
cause a lot of applications to break (no `/etc/passwd`, for example), but
it's enough to boot to a shell, so we'll live with it for the sake of
brevity.  If you want to flesh it out more you can refer to
[these](http://www.linuxfromscratch.org/lfs/view/stable/chapter07/creatingdirs.html)
[sections](http://www.linuxfromscratch.org/lfs/view/stable/chapter07/createfiles.html)
of Linux From Scratch.

One absolutely critical piece of our userland that's still missing is an
`init` program. We'll just write a tiny shell script and use it as our
`init`:

    # vi /teeny/initramfs/x86-busybox/init

And enter the following:

```
#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys

echo -e "\nBoot took $(cut -d' ' -f1 /proc/uptime) seconds\n"

exec /bin/sh
```

and make it executable:

    # chmod +x /teeny/initramfs/x86-busybox/init

The Gentoo wiki's
[Custom Initramfs](https://wiki.gentoo.org/wiki/Custom_Initramfs) page is a
great reference for building a minimalistic initramfs if you'd like to
learn more.

We're now ready to `cpio` everything up:

    # cd /teeny/initramfs/x86-busybox
    # find . -print0 \
        | cpio --null -ov --format=newc \
        | gzip -9 > /teeny/obj/initramfs-busybox-x86.cpio.gz

We now have a minimal userland in `$TOP/obj/initramfs-busybox-x86.cpio.gz`
that we can pass to `qemu` as an `initrd` (using the `-initrd` option).
But before we can do that we need a kernel...

# Linux Kernel

## Basic Kernel Config

For our not-yet-trimmed-down baseline, let's build a kernel using the
default `x86_64` configuration that ships with the kernel tree. Apply the
configuration like so:

    # cd /teeny/linux-5.11.7
    # make O=../obj/linux-x86-basic x86_64_defconfig

We can also merge in a few config options that improve
performance/functionality of kvm guests with:

    # make O=../obj/linux-x86-basic kvm_guest.config

The kernel is now configured and ready to build.  Go ahead and build it:

    # make O=../obj/linux-x86-basic -j$(nproc)

Your freshly built kernel image is located at
`$TOP/obj/linux-x86-basic/arch/x86_64/boot/bzImage`

Now that we have a kernel and a userland, we're ready to boot!

Exit your build container:

    # exit

Now you can use `qemu-system-x86_64` to try out your new system:

    $ cd $TOP
    $ qemu-system-x86_64 \
        -kernel obj/linux-x86-basic/arch/x86_64/boot/bzImage \
        -initrd obj/initramfs-busybox-x86.cpio.gz \
        -nographic -append "console=ttyS0"

Exit the VM by hitting `Ctl-a c` then typing "quit" at the `qemu` monitor
shell.

If your host processor and kernel have
[virtualization extensions](https://wiki.archlinux.org/index.php/KVM#Checking_support_for_KVM)
you can add the `-enable-kvm` flag to really speed things up:

    $ qemu-system-x86_64 \
        -kernel obj/linux-x86-basic/arch/x86_64/boot/bzImage \
        -initrd obj/initramfs-busybox-x86.cpio.gz \
        -nographic -append "console=ttyS0" -enable-kvm

## Smaller Kernel Config

That's great and all, but if we really just want a tiny system with nothing
but `busybox` on it we can remove a bunch of stuff from our kernel.  By
trimming down our kernel config we can reduce the size of our kernel image
and reduce boot time.

Let's try using the kernel's Kbuild defaults as our baseline.  The Kbuild
defaults are generally quite conservative since Linus Torvalds has declared
that in the kernel
[unless the feature cures cancer, it's not on by default](http://lwn.net/Articles/377102/),
as opposed to the `x86_64_defconfig` which is meant to provide a lot of
generally useful features and work on a wide variety of x86 targets.

To get started, re-enter our build container:

    $ docker run -ti -v $TOP:/teeny teeny-linux-builder

You can apply this more conservative configuration based on the Kbuild
defaults by using the `alldefconfig` target:

    # cd /teeny/linux-5.11.7
    # make O=../obj/linux-x86-alldefconfig alldefconfig

We need to enable a few more options in order to actually be able to use
this configuration.

First, we need to enable a serial driver so that we can get a serial
console.  Run your preferred kernel configurator (I like `nconfig`, but you
can use `menuconfig`, `xconfig`, etc.):

    # make O=../obj/linux-x86-alldefconfig nconfig

Navigate to:

    -> Device Drivers
      -> Character devices
        -> Serial drivers

and enable the following options:

  - `[*] 8250/16550 and compatible serial support`
  - `[*] Console on 8250/16550 and compatible serial port`

We also need to enable `initramfs` support, so that we can actually boot
our userland.  Go to:

    -> General setup

and select:

  - `[*] Initial RAM filesystem and RAM disk (initramfs/initrd) support`

You can also deselect all of the initrd/initramfs decompressors except
`gzip`, since that's the only one we're using.

You can now exit, saving changes.

Finally, enable some features for `kvm` guests (not actually necessary to
get the system booting, but hey):

    # make O=../obj/linux-x86-alldefconfig kvm_guest.config

Build:

    # make O=../obj/linux-x86-alldefconfig -j$(nproc)

And exit the build container:

    # exit

We now have a much smaller kernel image:

    $ (cd $TOP; du -hs obj/linux-x86-*/vmlinux)
    19M     obj/linux-x86-alldefconfig/vmlinux
    54M     obj/linux-x86-basic/vmlinux

Now boot the new kernel (with our same userspace):

    $ qemu-system-x86_64 \
        -kernel obj/linux-x86-alldefconfig/arch/x86_64/boot/bzImage \
        -initrd obj/initramfs-busybox-x86.cpio.gz \
        -nographic -append "console=ttyS0" -enable-kvm

Not only is it smaller than the last one, but it boots faster too! Here are
the results on my system:

<table>
  <tr>
    <th>Configuration</th>
    <th>Boot time (seconds)</th>
  </tr>
  <tr>
    <td><code>x86_64_defconfig + kvmconfig</code></td>
    <td><code>0.74</code></td>
  </tr>
  <tr>
    <td><code>alldefconfig + custom stuff + kvmconfig</code></td>
    <td><code>0.32</code></td>
  </tr>
</table>

## Smallest Kernel Config

We saw a nearly 3x decrease in kernel image size and cut boot time in half
by using a smaller set of default options.  But how much smaller and
"faster" can we go?

Let's prune the image down even further by starting with absolutely
nothing.  The kernel build system has a `make` target for this:
`allnoconfig`. Let's create a new configuration based on that.

Enter the build container again:

    $ docker run -ti -v $TOP:/teeny teeny-linux-builder

And start an `allnoconfig` build configuration:

    # cd /teeny/linux-5.11.7
    # make O=/teeny/obj/linux-x86-allnoconfig allnoconfig

Now everything that *can* be turned off *is* turned off.  This is as low as
it goes without hacking up the kernel source.  As one might expect, we have
a little more work to do in order to get something that actually boots in
`qemu`. Incredibly, though, there isn't a ton to do.

Fire up your kernel configurator:

    # make O=../obj/linux-x86-allnoconfig nconfig

Here are the options you need to turn on:

    [*] 64-bit kernel

    -> General setup
      -> Configure standard kernel features
    [*] Enable support for printk

    -> General setup
    [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support

    -> Executable file formats
    [*] Kernel support for ELF binaries
    [*] Kernel support for scripts starting with #!

    -> Device Drivers
      -> Character devices
    [*] Enable TTY

    -> Device Drivers
      -> Character devices
        -> Serial drivers
    [*] 8250/16550 and compatible serial support
    [*]   Console on 8250/16550 and compatible serial port

    -> File systems
      -> Pseudo filesystems
    [*] /proc file system support
    [*] sysfs file system support

And exit, saving changes.

In order to keep things truly tiny, we'll skip `make kvmconfig`. Build it:

    # make O=../obj/linux-x86-allnoconfig -j$(nproc)

and exit the build container:

    # exit

The resulting image is quite a bit smaller than our last one, and nearly
10x smaller than the one based on `x86_64_defconfig`:

    $ (cd $TOP; du -hs obj/linux-x86-*/vmlinux)
    19M     obj/linux-x86-alldefconfig/vmlinux
    6.1M    obj/linux-x86-allnoconfig/vmlinux
    54M     obj/linux-x86-basic/vmlinux

Adding `make kvm_guest.config` increases the image size to 9M.

And boot it:

    $ qemu-system-x86_64 \
        -kernel obj/linux-x86-allnoconfig/arch/x86_64/boot/bzImage \
        -initrd obj/initramfs-busybox-x86.cpio.gz \
        -nographic -append "console=ttyS0" -enable-kvm

Our new tiniest kernel boots about twice as fast as the `alldefconfig` one
and about 5x as fast as the one based on `x86_64_defconfig`.  Adding
`kvmconfig` didn't really affect boot time.

<table>
  <tr>
    <th>Configuration</th>
    <th>Boot time (seconds)</th>
  </tr>
  <tr>
    <td><code>x86_64_defconfig + kvmconfig</code></td>
    <td><code>0.74</code></td>
  </tr>
  <tr>
    <td><code>alldefconfig + custom stuff + kvmconfig</code></td>
    <td><code>0.32</code></td>
  </tr>
  <tr>
    <td><code>allnoconfig + custom stuff</code></td>
    <td><code>0.28</code></td>
  </tr>
</table>

# Conclusion

The most obvious application for this type of work is in the embedded
space. However, I could see how it might also be beneficial in elastic
cloud computing to reduce boot times and memory footprint. Please leave a
comment if you're aware of anyone doing this in "the cloud"!

If nothing else it's an interesting exercise! :)
