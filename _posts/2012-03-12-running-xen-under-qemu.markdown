---
layout: post
title: Running Xen Under Qemu
tags: [linux, qemu, xen]
---

<div class="alert-message info">

<b>Note</b>: I never got any guest OS's working, so this post is kind
of falls off a cliff at the end... However, I think the setup process
is still interesting, so I'm leaving it here.

 </div>

I've been trying to learn more about hypervisors lately since, well,
they're awesome. Also, I've always wanted to learn `qemu`, so I
decided to try using `qemu` as a sort of hypervisor "prototyping"
area. In this post I'll be documenting how I got `Xen` running under
`qemu` with a Debian guest. It's a dome within a dome *within a dome*
(within some more domes?). Suffice it to say there are a lot of
domes. At the highest level possible:

    +------------------------------+
    | Arch Linux                   |
    | +---------------------------+|
    | | qemu                      ||
    | | +------------------------+||
    | | | dom0 (Fedora16 + Xen)  |||
    | | | +------+     +------+  |||
    | | | |domU  |     |domU  |  |||
    | | | |Debian| ... | BSD  |  |||
    | | | |      |     |      |  |||
    | | | |      |     |      |  |||
    | | | +------+     +------+  |||
    | | +------------------------+||
    | +---------------------------+|
    +------------------------------+

This is going to get really slow, quickly. And it's going to be
awesome.

# Preparation and Setup

First, you need to know whether or not you'll be running `qemu` with
`KVM` support. `KVM` is a Linux kernel module that allows user space
programs to access hardware virtualization features of the CPU. You
can only use `KVM` if you have an Intel CPU with VT-x extensions, or
an AMD CPU with SVM or AMD-V extensions. You can check
[this](http://wiki.xensource.com/xenwiki/HVM_Compatible_Processors)
list or examine your `/proc/cpuinfo` to check for virtualization
support:

    $ egrep '(vmx|svm)' /proc/cpuinfo

I'm running an Intel Core 2 Duo, T6600, which doesn't have VT-x, so
I'll be running `qemu` without `KVM` support. This also means I can't
emulate other architectures; I'll only be able to emulate x86_64 (**is
this true?**).

## Qemu Installation

I'm running [Arch Linux](http://www.archlinux.org/), so I install
`qemu` like so:

    $ sudo pacman -S qemu

## Create a Hard Disk for Virtual Machine

Since I want to have a persistent "hard disk", I create a 20GB one now
using `qemu-img`:

    $ qemu-img create -f qcow2 disk.img 20G

`-f qcow2` tells `qemu-img` to use the `qcow2` image format, which is
described in the `qemu-img` `man` page as follows:

    qcow2
        QEMU image format, the most versatile format. Use it to have
        smaller images (useful if your filesystem does not supports holes,
        for example on Windows), optional AES encryption, zlib based
        compression and support of multiple VM snapshots.

See the man page for more info about the various options. I'm
especially interested in snapshots and the "backing_file" option,
(also known as "overlay images") which basically lets you create a
baseline image and then create VMs whose disks are "deltas" of the
baseline, resulting in lower disk usage and the possibilty of
care-free experimentation.

# Install the dom0

Xen requires that a dedicated guest, named "domain 0" (or dom0) be
installed to take care of some of the hardware abstraction and guest
OS management. This is usually a Linux or other Unix OS with special
modifications for Xen support.

Initially I tried using the
[Xen Cloud Platform](http://www.xen.org/download/xcp/index_1.5.0.html)
distribution but was having issues accessing the console of any guest
machine I created. If I were using real hardware I would most likely
use XCP for the dom0. It's a stripped down Linux install with support
for a bunch of cool tools like
[OpenXenManager](http://sourceforge.net/projects/openxenmanager/),
[XenCenter](http://community.citrix.com/display/xs/XenCenter), etc. as
well as a bunch of ready-made templates for guest OSes.

Since XCP didn't pan out, I ended up simply installing Fedora 16 to
use as the dom0. The overall installation took a very long time since
`qemu` is doing all the emulation in software on my machine. I
probably should have done a text-based install to try to keep things
as slim as possible, oh well.

After the install is complete, I shut down the machine, and make a
"baselined" disk, which only stores the deltas from our original disk.

    $ qemu-img create -b disk.img -f qcow2 overlay1.img

And bring the machine back up without the cdrom:

    $ qemu-system-x86_64 -hda overlay1.img -m 1024

At this point I do the usual updates and then install the `xen`
package group to enable support for the hypervisor:

    # yum update
    # yum install xen

I lay down an overlay at this point since it's a good checkpoint that
I can come back to if I mess things up. To do this simply hit
`ctl-alt-shift-2` to access the `qemu` console, then type:

     (qemu) savevm installed-xen

# Install some Guests

If your CPU doesn't support hardware virtualization, your guest OSes
will need to be "paravirtualized" for Xen. This means that the kernel
has been modified so that certain system calls are routed directly to
the hypervisor. With hardware virtualization, on the other hand, those
"unsafe" instructions instead cause a CPU exception and then are
re-routed to the hypervisor. Almost paradoxically, *hardware
virtualization is slower than paravirtualization*!. This is mainly due
to the overhead involved with CPU
exceptions. [Here](http://www.ok-labs.com/) is a great whitepaper by
the folks over at [ok-labs](http://www.ok-labs.com/) if you want to
understand more of the nitty gritty behind how hypervisors work.

Paravirtualization is a little more difficult to use since it involves
modifying the guest operating system. However, more and more OSes are
adding support built-in for paravirtualization. For example, recent
versions of the Linux kernel have paravirtualization support (and it
is enabled as a module by default in some distros).

**I never got any guests to work :(**
