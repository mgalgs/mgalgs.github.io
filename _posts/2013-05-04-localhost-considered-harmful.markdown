---
layout: post
title: localhost considered harmful (nginx ipv6 fun)
tags: [nginx, centos, linux, django, gunicorn]
---

After a recent update to one of my CentOS servers that hosts some
django applications, I started getting 502's with the following error
message:

    2013/05/05 10:06:04 [alert] 1771#0: *22 socket() failed (97: Address family not supported by protocol) while connecting to upstream, client: X.X.X.X, server: example.com, request: "GET /bid/ HTTP/1.1", upstream: "http://[::1]:8001/bid/", host: "example.com:81"

To make matters worse, I was only seeing this error message
intermittently. I could refresh the page 10 times and only see this
error 5/10 times.

Everything I found online said something about commenting out a line
like this one in your `nginx` config:

    listen   [::]:80 default ipv6only=on;

However, I didn't have such a line in any of my configs. Then I
noticed the following snippet from the error message above:

    upstream: "http://[::1]:8001/bid/"

and realized that `nginx` (or, more likely, the system routing code)
was resolving `localhost` to `::1` (which is `localhost` in `ipv6`)! I
considered editing my `/etc/hosts` file to remove the `::1` alias from
`localhost` but then settled on a cleaner solution: **replacing all
instances of `localhost` in my `nginx` config files with
`127.0.0.1`**.

**The moral of the story:** `localhost` might not mean what you think
it means! Don't use `localhost` unless you really support both `ipv4`
and `ipv6`. Instead, use `127.0.0.1` and `::1`.
