---
layout: post
title: Running Xen Under Qemu
tags: [linux, qemu, xen, workinprogress]
---

I've been trying to learn more about hypervisors lately since, well,
they're awesome. Also, I've always wanted to learn `qemu`, so I
decided to use `qemu` as a sort of hypervisor "prototyping" area. In
this post I'll be documenting how I got `Xen` running under `qemu`
with **INSERT GUEST OS's HERE** guests. (Really they're guests within
a guest. A dome within a dome. A DomU within a Dom0 :).)

# Preparation and Setup

I'm going to be running `qemu` on a Linux host.

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

### Short Digression: Bridge Interfaces

Ethernet software
[bridges](http://www.linuxfoundation.org/collaborate/workgroups/networking/bridge)
in Linux are extremely powerful. Basically, they allow you to combine
multiple physical interfaces into one logical "bridge" device. When a
packet arrives at a physical interface that is slaved to a bridge
device, the bridge interface can steal the packet and deliver it up to
userspace programs that are bound to the bridge
interface. Alternatively, you can use
[`ebtables`](http://ebtables.sourceforge.net/) to do filtering at the
Ethernet layer of packets passing through the bridge interface.

Bridges are particulary useful if you're building a router or a proxy
server. Maybe sometime I'll do a post dedicated to software bridges...

## Obtain Xen Installation Media

To make things as simple as possible, I'm using a ready-made "Xen
Cloud Platform (XCP) Appliance". Specifically, I'm using XCP 1.5 Beta,
available [here](http://www.xen.org/download/xcp/index_1.5.0.html).

# Xen Installation

To install Xen in our `qemu` environment, we start the x86\_64
emulator with our downloaded XCP iso as the cdrom device, our freshly
created hard disk image as hda, and 1GB of RAM (the default 128MB is
not enough to run Xen):

    $ qemu-system-x86_64 -cdrom XCP-1.5-beta-base-53341.iso -hda disk.img -m 1024

We click through some menus like these (I'm omitting some of the more
boring ones):

<a href="http://i.imgur.com/Dj3sd.png"><img width="500" src="http://i.imgur.com/Dj3sd.png" /></a>
<a href="http://i.imgur.com/kFc9r.png"><img width="500" src="http://i.imgur.com/kFc9r.png" /></a>
<a href="http://i.imgur.com/wa3xj.png"><img width="500" src="http://i.imgur.com/wa3xj.png" /></a>
<a href="http://i.imgur.com/9W5rP.png"><img width="500" src="http://i.imgur.com/9W5rP.png" /></a>
<a href="http://i.imgur.com/uFJ8t.png"><img width="500" src="http://i.imgur.com/uFJ8t.png" /></a>
<a href="http://i.imgur.com/DKDws.png"><img width="500" src="http://i.imgur.com/DKDws.png" /></a>
<p>Nice panda!</p>
<a href="http://i.imgur.com/MirTm.png"><img width="500" src="http://i.imgur.com/MirTm.png" /></a>
<a href="http://i.imgur.com/W464D.png"><img width="500" src="http://i.imgur.com/W464D.png" /></a>
<a href="http://i.imgur.com/XXRvQ.png"><img width="500" src="http://i.imgur.com/XXRvQ.png" /></a>
<p>Ta-Da!</p>
<a href="http://i.imgur.com/psxqW.png"><img width="500" src="http://i.imgur.com/psxqW.png" /></a>

We'll shut the system down now so that we can boot directly from the
hard disk for further configuration.

Since we have a pristine install of Xen XCP, now would be a good time
to lay down an overlay image:

    $ qemu-img create -b disk.img -f qcow2 overlay1.img

This creates a new hard disk image named overlay1.img that will only
contain deltas from disk.img. If we trash our system, we can always
revert back to this current pristine state.

<br/>

# Xen Configuration

We can boot the Xen system that we just installed by getting rid of
the `-cdrom` argument:

    $ qemu-system-x86_64 -hda disk.img -m 1024

## Adding Guests

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
adding support by default for paravirtualization. For example, recent
versions of the Linux kernel have paravirtualization support (and it
is enabled as a module by default in some distros).

Anyways, it just so happens that there are a bunch of pre-built Linux
kernel images out there that support paravirtualization. Also, XCP
comes with a bunch of "templates" that can be used to create VMs at
will.

We can install some VMs from the XCP templates by running some
commands on the command shell on the Xen Dom0 "Local Command Shell"
(which is simply a root Linux `bash` shell).

    # xe vm-install template=Debian\ Squeeze\ 6.0\ \(32-int\) new-name-label=SqueezeVM
    # xe vm-param-set uuid=<uuid of vm> other-config:install-repository=http://ftp.debian.org
    # xe network-list # note the uuid of the xenbr0 interface
    # xe vif-create network-uuid=<uuid of xenbr0> vm-uuid=<uuid of vm> device=0
    # xe vm-start uuid=<uuid of vm>

When `xe vm-start` returns the Debian installer should be waiting for
us on the console for our new VM!

Now would be a good time to save a snapshot of the `qemu` image. Hit
`ctl-alt-shift-2` to access the `qemu` console, then type:

     (qemu) savevm added-squeeze

# dom0 Installation

    qemu-system-x86_64 -cdrom CentOS-6.2-x86_64-LiveCD.iso -hda disk.img -m 1024

    $ qemu-system-x86_64 -cdrom Fedora-16-x86_64-Live-Desktop.iso -hda disk.img -m 1024
