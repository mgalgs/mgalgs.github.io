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
a guest. A dome within a dome.)

### Preparation and Setup

First, you need to know whether or not you'll be running `qemu` with
`KVM` support. `KVM` is a Linux kernel module that allows user space
programs to access hardware virtualization features of the CPU. You
can only use `KVM` if you have an Intel CPU with VT-x extensions, or
an AMD CPU with SVM or AMD-V extensions. You can check
[this](http://wiki.xensource.com/xenwiki/HVM_Compatible_Processors)
list or examine your `/proc/cpuinfo` to check for virtualization
support:

    # egrep '(vmx|svm)' /proc/cpuinfo

I'm running an Intel Core 2 Duo, T6600, which doesn't have VT-x, so
I'll be running `qemu` without `KVM` support. This also means I can't
emulate other architectures; I'll only be able to emulate x86_64 (**is
this true?**).

#### Qemu Installation

I'm running [Arch Linux](http://www.archlinux.org/), so I install
`qemu` like so:

    # sudo pacman -S qemu

#### Create a Hard Disk for Virtual Machine

Since I want to have a persistent "hard disk", I create a 20GB one now
using `qemu-img`:

    # qemu-img create disk.img 20G

##### Short Digression: Bridge Interfaces

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

#### Obtain Xen Installation Media

To make things as simple as possible, I'm using a ready-made "Xen
Cloud Platform (XCP) Appliance". Specifically, I'm using XCP 1.5 Beta,
available [here](http://www.xen.org/download/xcp/index_1.5.0.html).

### Xen Installation

To install Xen in our `qemu` environment, we start the x86\_64
emulator with our downloaded XCP iso as the cdrom device, our freshly
created hard disk image as hda, and 1GB of RAM (the default 128MB is
not enough to run Xen):

    # qemu-system-x86_64 -cdrom XCP-1.5-beta-base-53341.iso -hda disk.img -m 1024

We click through some menus like these (omitting some of the more
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

We'll shut the system down now so that we can boot from the hard disk
for further configuration.

<br/>
<br/>

### Xen Configuration

We can boot the Xen system that we just installed by getting rid of
the `-cdrom` argument:

    # qemu-system-x86_64 -hda disk.img -m 1024
