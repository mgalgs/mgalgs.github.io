---
layout: post
title: Block Invalid Http Hosts With Haproxy And Django
tags: [haproxy, nginx]
---

In Django >= 1.5, an error is logged every time a request comes in where
the HTTP host header isn't present in your `ALLOWED_HOSTS` setting.  You'll
see error messages (and probably emails) with stuff like:

    Invalid HTTP_HOST header: ‘www.baidu.com’. You may need to add u'www.baidu.com' to ALLOWED_HOSTS.

Search engine crawlers and vulnerability scanners often set this header, so
these error messages get annoying fast.  As described
[here](http://stackoverflow.com/questions/15238506/djangos-suspiciousoperation-invalid-http-host-header),
one good way of dealing with this problem is to kill these requests before
they even hit your Django app.  There's an example of how to do this with
`nginx` [here](http://stackoverflow.com/a/17477436/209050).

If you're using `haproxy` you can achieve a similar result with an acl and
a backend:

    frontend whatever
        mode http
        ...
        acl is_example_com hdr_end(host) -i example.com
        use_backend bogus if !is_example_com
    
    backend bogus
        errorfile 400 /etc/haproxy/errors/400.http
