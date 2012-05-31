---
layout: post
title: Fedora Does Have A Niche
tags: [linux, fedora, linux-action-show]
---

It's for developers!

I was glad that
[the LAS Fedora 17 review](http://www.jupiterbroadcasting.com/19962/fedora-17-review-las-s22e01/)
was mostly positive, but thought I would pipe in with some thoughts on
strong use cases for Fedora, since our buddies B-Man and C-Man were
struggling to articulate exactly what sets Fedora apart from other
distros. Full disclaimer: I've only been using Fedora for about 6
months, so maybe I'm being hasty in my conclusions... Also, I respect
every distro for different reasons, I'm not trying to flame anyone.

I've been using [Arch Linux](http://www.archlinux.org/) at home for
about two years now and love it. Before that I was using Ubuntu but
got sick of how out-of-date all the packages were. Arch is great for
staying on bleeding edge of things, but here's the thing: stuff breaks
every so often. It just does. It seems to be happening a lot more
often lately than in the past (I swear gnome 3 is making `[extra]`
feel more like `[testing]` lately), for me at least. Now, I'm *totally
fine* with that for my machines at home. I can fiddle and fix things
and when I really do find a bug it feels good to be able to contribute
to upstream projects through bug reports and the occasional patch.

That's all fine and dandy, but if I have work to do I really don't
want to spend 2 hours (or even 20 minutes) debugging `nouveau` or
`libcups` or `libpizzafeast` or whatever. I just want to do work. And
I don't want to be stuck with 30 year-old packages, so that rules out
Ubuntu and friends. With Fedora you get to be *almost* (seriously!) as
bleeding edge as Arch, but it feels a *lot* more stable (and in some
cases you're actually *more* bleeding edge than Arch!). Just one quick
example, look at the differences between the `libnetfilter_queue`
packages provided by Arch, Fedora, and Ubuntu:

<table>
<tr>
<th>Distribution</th>
<th>Package Link</th>
<th>Package Freshness</th>
</tr>

<tr>
<td>Fedora</td>
<td><a href="https://admin.fedoraproject.org/pkgdb/acls/name/libnetfilter_queue"><code>libnetfilter_queue</code> on Fedora</a> (you have to click the "Update Status" link to see package version info)</td>
<td>version <b>1.0.1</b> of upstream, currently 4 months old, (it's the
latest upstream release)</td>
</tr>

<tr>
<td>Arch</td>
<td><a href="http://www.archlinux.org/packages/community/i686/libnetfilter_queue/"><code>libnetfilter_queue</code> on Arch</a></td>
<td>version <b>1.0.0</b> of upstream, currently 22 months old </td>
</tr>

<tr>
<td>Ubuntu</td>
<td><a href="http://packages.ubuntu.com/precise/libnetfilter-queue-dev"><code>libnetfilter_queue</code> on Ubuntu</a></td>
<td>version <b>0.0.17</b>, currently <i>3 years old</i> </td>
</tr>

</table>

This seems to be the basic pattern for many development libraries. To
be fair to my buddy Arch, there is an
[AUR package for `libnetfilter_queue`](https://aur.archlinux.org/packages.php?ID=59142)
that tracks the upstream git repo. However, as with all AUR packages,
there's no telling when it will be abandoned or broken. If it does get
abandoned you could always pick it up and start maintaining it, but
then we're right back to where we started about getting work done...

I've been using Fedora at work and at home for my development machine
for about 6 months now, and haven't had a single breakage. I really
think it might be the ideal platform for developers... And it doesn't
hurt its street cred that it's
[Linus Torvalds' distro of choice](http://news.oreilly.com/2008/07/linux-torvalds-on-linux-distri.html)
(the article is old, so this may not even be true any more) :).

**In short**, I know any distribution can work just fine for
development, but my experience is that Fedora has the best balance
between rock-solid stability and bleeding edge, providing just the
right temperature to be a majorly awesome development platform.
