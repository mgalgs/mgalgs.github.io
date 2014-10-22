---
layout: post
title: Enable arcfour and Other Fast Ciphers on Recent Versions of OpenSSH
tags: [linux, ssh]
---

After a recent update to my Arch Linux box I noticed that some of my backup
scripts started complaining about not being able to connect to my machine.
The error message I was seeing was:

    mgalgs@remote-host $ ssh -c arcfour my-machine
    no matching cipher found: client arcfour server aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com,chacha20-poly1305@openssh.com

This is because OpenSSH 6.7
[disables a few ciphers by default](http://www.openssh.com/txt/release-6.7)
for security reasons.  However, I'm only making these connections within my
trusted LAN so frankly I don't care about the security of my ssh cipher.
Heck, I'd even be ok with plain-text.

To get these fast (but *insecure*) ciphers back, you need to add a
`Ciphers` line to your `/etc/ssh/sshd_config`, like:

    Ciphers cipher1,cipher2,cipher3

Check the man page on your system for the default value and just add
`arcfour` to it.  You can get a list of *all* available ciphers by querying
your system with `ssh -Q`.  Pipe that sucker into `paste` and you have
yourself a line suitable for pasting into `/etc/ssh/sshd_config`:

    $ ssh -Q cipher localhost | paste -d , -s

Here's what I ended up adding to my `/etc/ssh/sshd_config`:

    # enable all ciphers!
    # obtained with ssh -Q cipher localhost | paste -d , -s
    Ciphers 3des-cbc,blowfish-cbc,cast128-cbc,arcfour,arcfour128,arcfour256,aes128-cbc,aes192-cbc,aes256-cbc,rijndael-cbc@lysator.liu.se,aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com,chacha20-poly1305@openssh.com

Remember, **only do this if you don't care about security** (i.e. you never
accept connections from outside your trusted network).
