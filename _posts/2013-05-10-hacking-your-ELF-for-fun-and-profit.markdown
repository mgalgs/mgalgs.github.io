---
layout: post
title: Hacking Your ELF For Fun And Profit
tags: [C, gcc, ELF, linux]
---

Have you ever wondered how the Linux kernel `module_init` and
`*_initcall`(e.g. `subsys_initcall`) macros work? Even after a quick
glance at their definition things might not be exactly clear:

{% gist 5557198 %}

The key to understanding what's going on here is understanding that
`__attribute__((__section__(...)))` business. Normally, variables are
placed in sections like `data` or `bss`. But with gcc, you can use the
[section attribute](http://gcc.gnu.org/onlinedocs/gcc/Variable-Attributes.html)
to manually specify which section of the ELF (assuming you're
compiling to ELF) you'd like that variable to live in.

### Custom ELF Sections

Using custom ELF sections, you can essentially build dynamic arrays of
arbitrary data *at compile time*. No need to modify the calling code
or register your function at runtime.

We'll walk through the Linux kernel example a little later, but first
let's look at a simple example of how this works in plain-ol' C.

#### Simple Plugin Architecture

Imagine that you're building a C program that you would like others to
be able to easily extend. One way you could accomplish this is by
providing a plugin system based on custom ELF sections. Maybe you want
other developers to be able to add functions to permute and print out
some text without having to modify your main program source code. The
following types and macros should do the trick:

{% gist 5537133 section_hacking.h %}

Notice the `__attribute((__section__("my_formatters")))`. That's the
key. With this, the `REGISTER_FORMATTER` macro will put functions
inside an ELF section called `my_formatters`. The macro can then be
used like so:

{% gist 5557388 %}

You can then iterate over all of the functions in the `my_formatters`
ELF section (all those that were registered with `REGISTER_FORMATTER`)
in your main program, like so:

{% gist 5557407 %}

Note the usage of the special variables `__start_my_formatters` and
`__stop_my_formatters`. `gcc` (`ld`, rather) includes these variables
for extra ELF sections as long as the section name will result in a
valid C variable name (e.g. it can't start with a "." (which is one
way to prevent these variables from being generated
automatically)). In general, the variables will be named
`__start_SECTION` and `__stop_SECTION`. I couldn't find any formal
documentation for this feature, only a few obscure mailing list
references. If you know where the docs are, drop a comment!

In the end, the main code for your program might look something like
this:

{% gist 5537133 section_hacking.c %}

And someone could provide a plugin file like this:

{% gist 5537133 plugin.c %}

Compile with this:

{% gist 5537133 Makefile %}

And you'll get the following output when you run your program:

{% gist 5537133 output.txt %}



#### Linux Kernel Init Calls

Back to our original example of the Linux kernel init calls.  The idea
here is to collect a bunch of different functions that correspond to
the various stages of boot into separate ELF sections so that they can
be executed in sequence, *without having to modify the code that
actually calls them*. At boot time, for each section, the kernel
simply takes the address of the section and starts iterating over the
functions it finds there, calling them in sequence. The code that does
that is the following three functions: `do_initcalls`,
`do_initcall_level`, and `do_one_initcall`, shown here:

{% gist 5557318 %}

{% gist 5557524 %}

{% gist 5557487 %}

This simply iterates over each section, and for each function found
within a section, simply calls the function. It's really pretty simple
and quite elegant if you ask me.

Note that rather than relying on `gcc` to emit those magical
`__start_SECTION` and `__stop_SECTION` variables, the Linux kernel
actually sets up its custom ELF sections by hand in a linker script:

{% gist 5557541 %}

If you're curious, the call path from `start_kernel` (the entry point
to the Linux kernel) to `do_initcalls` is as follows:

    start_kernel
    |
    `--> rest_init
         |
         `--> kernel_init
              |
              `--> do_basic_setup
                   |
                   `--> do_initcalls


### Summary

Custom ELF sections can be useful for accumulating similar data
(function pointers, for example) at compile time. With `gcc` magic
variables or custom linker scripts you can access the start and end of
those sections at runtime.

Now go hack some ELFs!
