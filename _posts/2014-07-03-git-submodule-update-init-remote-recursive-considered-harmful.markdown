---
layout: post
title: git submodule update --init --remote --recursive Considered Harmful
tags: [git]
---

I use a repository ([gh.el](https://github.com/sigma/gh.el)) that has a submodule to itself. The `.gitmodules` looks like:

    [submodule "docs/build/html"]
    	path = docs/build/html
    	url = git://github.com/sigma/gh.el.git

That's right. We're adding a submodule located at `docs/build/html`
that points to... ourselves.

The purpose (I believe) is to make it more convenient to edit the
documentation for the project, since GitHub's convention is to host
project documentation from a specially-named branch within your
project that has no common ancestor with your project itself. It's
kind of a neat trick.

The problem is when I try to do a `git submodule update --remote
--recursive`. I get stuck in an infinite recursion of submodule
checkouts. You can reproduce it yourself with:

    $ git clone https://github.com/sigma/gh.el.git
    $ cd gh.el
    $ git submodule update --init

All fine and dandy up to this point... But now try this:

    $ git submodule update --init --remote --recursive

You'll see `docs/build/html` being cloned recursively forever like so:

    Submodule path 'docs/build/html': checked out 'a1b24e13d368e0595d147e9b068e6904c1514c19'
    Submodule 'docs/build/html' (git://github.com/sigma/gh.el.git) registered for path 'docs/build/html'
    Cloning into 'docs/build/html'...
    remote: Reusing existing pack: 849, done.
    remote: Total 849 (delta 0), reused 0 (delta 0)
    Receiving objects: 100% (849/849), 249.11 KiB | 375.00 KiB/s, done.
    Resolving deltas: 100% (438/438), done.
    Checking connectivity... done.
    Submodule path 'docs/build/html/docs/build/html': checked out 'a1b24e13d368e0595d147e9b068e6904c1514c19'
    Submodule 'docs/build/html' (git://github.com/sigma/gh.el.git) registered for path 'docs/build/html'
    Cloning into 'docs/build/html'...
    remote: Reusing existing pack: 849, done.
    remote: Total 849 (delta 0), reused 0 (delta 0)
    Receiving objects: 100% (849/849), 249.11 KiB | 0 bytes/s, done.
    Resolving deltas: 100% (438/438), done.
    Checking connectivity... done.
    Submodule path 'docs/build/html/docs/build/html/docs/build/html': checked out 'a1b24e13d368e0595d147e9b068e6904c1514c19'
    ...

# The Lesson

**Don't use `git submodule update --init --remote --recursive`**. I
generally stick to a two step process:

    $ git submodule update --init --recursive
    $ git submodule update --remote

and let the submodules handle their own submodules, or something like
that. Recursion is fun.
