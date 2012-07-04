---
layout: post
title: Handbrake TUI
---

Recently I've been busy digitizing my video and music collection to
store on
[my new FreeNAS machine](/2012/04/24/freenas-hardware-build.html). I've
been using [HandBrake](http://handbrake.fr/) a lot and haven't been
satisfied with the options for automated ripping on Linux. So I wrote
a simple handbrake text-based user interface
([TUI](http://en.wikipedia.org/wiki/Text-based_user_interface)) in
bash that I thought others might find useful.

You can download it
[here](https://raw.github.com/mgalgs/scripts/master/ripdvd.sh).


Here's a \`screenshot' of it in action:

    $ ripdvd.sh

    [selected] [ismainfeature] [ id]     Title...
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
       [x]           [x]       [  1]     Title: 01, Length: 02:19:52.153 Chapters: 40, Cells: 40, Audio streams: 03, Subpictures: 03
       [x]           [ ]       [  2]     Title: 02, Length: 00:00:12.033 Chapters: 01, Cells: 01, Audio streams: 03, Subpictures: 03
       [x]           [ ]       [  3]     Title: 03, Length: 00:00:12.000 Chapters: 01, Cells: 01, Audio streams: 03, Subpictures: 03
       [x]           [ ]       [  4]     Title: 04, Length: 00:00:07.000 Chapters: 01, Cells: 01, Audio streams: 03, Subpictures: 03
       [x]           [ ]       [  5]     Title: 05, Length: 00:00:21.020 Chapters: 01, Cells: 01, Audio streams: 03, Subpictures: 03
       [ ]           [ ]       [  6]     Title: 06, Length: 00:01:13.033 Chapters: 01, Cells: 01, Audio streams: 03, Subpictures: 03
       [ ]           [ ]       [  7]     Title: 07, Length: 00:00:00.176 Chapters: 01, Cells: 01, Audio streams: 03, Subpictures: 03
       [ ]           [ ]       [  8]     Title: 08, Length: 00:01:20.220 Chapters: 03, Cells: 03, Audio streams: 03, Subpictures: 01
       [x]           [ ]       [  9]     Title: 09, Length: 00:00:00.176 Chapters: 01, Cells: 01, Audio streams: 02, Subpictures: 03
    
    Menu:
    xN      : Toggle rip selection for title N
                (omit N to select/deselect all)
    pN      : Preview title N
    eN      : Toggle title N as a main feature
    q       : Quit
    <enter> : Go!
    
     >>> 

Some features include:

* Easily select titles for ripping
* Quickly preview titles using mplayer
* Automatic detection of "Main" feature titles based on their length
  (this can be overridden if you don't like the decision)
* Rip from a DVD (saving an iso as an intermediate step) or rip
  straight from an iso

Honestly I didn't spend a lot of time refining but it's actually
pretty flexible as it is. I really think it's the easiest way to use
HandBrake.
