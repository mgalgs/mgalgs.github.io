---
layout: post
title: Installing A Custom Openwrt Build On An ASUS RT-N16
tags: [openwrt, linux]
---

My home router has been acting up recently so I decided to take control of
it by installing [OpenWRT](https://openwrt.org/).  I've used
[DD-WRT](http://www.dd-wrt.com/) and
[tomato](http://www.polarcloud.com/tomato) in the past, but wanted
something a little more hackable and less shiny.  OpenWRT seems like a
perfect fit!

Luckily the base port for the RT-N16 is already done and there's a fairly
extensive (though outdated and at times inaccurate)
[entry for the RT-N16](http://wiki.openwrt.org/toh/asus/rt-n16) on the
OpenWRT wiki.  I was able to load the `Barrier Breaker 14.07` build on my
RT-N16 but only one of the ethernet ports worked...  I decided to try a
newer OpenWRT release to see if things would work any better.

Since `15.05` isn't officially released yet I decided I might as well set
my own build environment in case I want to do some additional
hacking/debugging.  The information needed to do so is kind of spread out
across the OpenWRT wiki, mailing list, and forum threads, so I thought I'd
document the process all in one place for any future wary travelers.

Most of this is documented on the OpenWRT wiki.  The main entry point for
the build system documentation is
[http://wiki.openwrt.org/about/toolchain](here).

# Getting the Sources

First, we'll clone the base OpenWRT tree:

    $ git clone git://git.openwrt.org/15.05/openwrt.git openwrt-15.05

Many of the OpenWRT packages are delivered in "package feeds" that need to
be initialized separately:

    $ cd openwrt-15.05
    $ ./scripts/feeds update -a
    $ ./scripts/feeds install -a

OpenWRT uses the [buildroot](http://buildroot.uclibc.org/) build system
which has an interface similar to
[the Linux kernel Kconfig](https://www.kernel.org/doc/Documentation/kbuild/kconfig-language.txt)
system.  These build systems include the concept of a "default config", or
"defconfig", which selects many of the rudimentary options necessary for
basic operation of a given target or platform.  We'll be using the
defconfig for the Broadcom system on which the RT-N16 is based as a
starting point.

In order for the OpenWRT build system to know *which* defconfig it should
use,
[you must select your target system](http://wiki.openwrt.org/doc/howto/build#defconfig)
before running `make defconfig`.  You do this through the `menuconfig`
interface:

    $ make menuconfig

For the RT-N16 we'll select:

    Target System: Broadcom BCM47xx/53xx (MIPS)
    Subtarget: MIPS 74K
    Target Profile: Broadcom SoC, BCM43xx WiFi (proprietary wl)

Don't worry about selecting any other packages yet.  You can now pull in
the options from the `defconfig` by running:

    $ make defconfig

We now have a nice baseline with all of the essentials for the RT-N16
selected.  We can now select any additional packages we'd like to include
in our firmware image:

    $ make menuconfig

A few of the packages I selected were `luci`, `kernel function tracer`,
`bash`, `msmtp`, and `tmux`.  I believe all of these except `kernel
function tracer` can be installed on your live target using
[`opkg`](http://wiki.openwrt.org/doc/techref/opkg) rather than building
them into the firmware image, but oh well.

You're now ready to build:

    $ make -jN |& tee build.log

where `N` equals the number of cpus on the build host plus one.  To
increase verbosity and also ignore build errors in optional modules, use:

    $ make -jN V=99 IGNORE_ERRORS=m |& tee build.log

Once that's done (took around an hour on my machine) our freshly-cooked
firmware image will be in the `bin/bcm47xx` directory.
