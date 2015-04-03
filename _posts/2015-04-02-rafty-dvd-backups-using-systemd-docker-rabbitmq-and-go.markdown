---
layout: post
title: Rafty -- DVD Backups using Systemd, Docker, Rabbitmq and go
tags: [docker, systemd, rabbitmq, go, udev]
---

Rafty is a little project I built to help automate the process of backing
up my DVD collection.

Rafty stands for **R**ipper **a**nd **F**riggin' **T**ranscoder, **Y**'all.

# Background

I recently decided it was time to make some more progress in my efforts to
fully backup my DVD collection.  After all, that was one of the main
reasons [I built a NAS]({% post_url 2012-04-24-freenas-hardware-build %}) a
few years ago (which I recently upgraded to 8TB of storage!).

I've scripted the `dd` -> `handbrake` process a few times in the past, but
this time I decided to do something a little more flexible.  A few of my
main requirements were:

  - User intervention shall only be required for the physical insertion and
    removal of discs.  (And I'd like to phase that out someday as well :).
    Need to build a robot...)

  - The system shall be capable of scaling out arbitrarily so that idle
    machines can be added to help speed things along.

This also seemed like the perfect opportunity for me to use a few pieces of
technology that I've been wanting to get my hands dirty with for a while.
Specifically:

  - [Systemd](http://www.freedesktop.org/wiki/Software/systemd/)
  - [Docker](https://www.docker.com/)
  - [rabbitmq](https://www.rabbitmq.com/)
  - [go](https://golang.org/)

# Architecture

The initial architecture ended up looking something like this:

<img src="/static/handbraked1.png">
([dot source](/static/handbraked1.dot))

To summarize:

  - `udev` listens for a DVD to be inserted and starts a "oneshot"
    `systemd` service.

  - The `systemd` service launches (and monitors) a script that uses `dd`
    to copy the disc to the local hard drive.

  - The script ejects the disc and uses `handbrakectl` (a program written
    in `go`) to submit a job to the `handbraked` daemon (another program
    written in `go`) through a `rabbitmq` named queue.

  - `handbraked` reads jobs off of the queue and invokes
    [Handbrake](https://handbrake.fr/) for transcoding.  The output is
    saved to the appropriate directory (on an 8TB
    [`btrfs`](https://btrfs.wiki.kernel.org) RAID-1 volume) where it is
    immediately available to media consumers on my home network.

It might seem like overkill (ok, ok, it *is* overkill) but a few fairly
interesting properties fall out of this architecture:

  - Optical disc drives can be utilized at full capacity.  We don't have to
    wait for the transcode phase to finish before starting another copy
    job.

  - Optical disc drives can be added arbitrarily.  Thanks to `udev` and
    `systemd` environment variables, there's no hard-coding of device
    paths.

  - Additional "copy frontends" can be added arbitrarily.  These can be
    local (using `handbrakectl` to submit jobs for existing isos, for
    example), or (more interestingly) remote machines.  This lets us scale
    out our disc copying work (IO-intensive).

  - Additional "transcoding backends" can be added arbitrarily by
    leveraging `rabbitmq`'s round-robin dispatch across consumers.  These
    can be local or remote.  All you'd need to do to spin up another remote
    compute node is run `handbraked` on the remote machine.  `rabbitmq`
    will take care of the rest.  This lets us scale out our transcoding
    work (CPU-intensive).

So with minimal code modifications (I'm actually hard-coding `localhost` in
`handbrakectl` and `handbraked` as the `rabbitmq` host), the system could
scale out to look like this:

<img src="/static/handbraked3.png" style="width:100%">
([full size](/static/handbraked3.png))
([dot source](/static/handbraked3.dot))

Those blue and red nodes can scale out virtually without limit.  The only
bottleneck here would be `rabbitmq` message throughput, and these messages
are tiny.  The bigger problem for me is the fact that I only have one
machine with a single optical disc drive to dedicate to this :).

Blatant over-engineering aside, this project was a lot of fun and helped me
learn more about some new and interesting technologies.  Hope you enjoyed
it!

# Source

If you want to run this behemoth at your house, head on over to the
official [Rafty](https://github.com/mgalgs/rafty) GitHub page.

  - `udev` rule: [98-dd-one-from-udev.rules](https://github.com/mgalgs/rafty/blob/master/98-dd-one-from-udev.rules)
  - `systemd` oneshot service: [dd-dvd@.service](https://github.com/mgalgs/rafty/blob/master/dd-dvd%40.service)
  - `dd-one.sh`: [dd-one.sh](https://github.com/mgalgs/rafty/blob/master/dd-one.sh)
  - `dd-one.conf`: [dd-one.conf](https://github.com/mgalgs/rafty/blob/master/dd-one.conf)
  - `handbrakectl.go`: [handbrakectl.go](https://github.com/mgalgs/rafty/blob/master/handbrakectl.go)
  - `handbraked.go`: [handbraked.go](https://github.com/mgalgs/rafty/blob/master/handbraked.go)
