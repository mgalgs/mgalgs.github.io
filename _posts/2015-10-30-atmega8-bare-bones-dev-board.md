---
layout: post
title: Atmega8 Bare Bones Dev Board
tags: [hardware, avr, atmega8]
---

Several years ago I decided it would be nice to have a simple dev board for
the Atmega8's I had laying around.  So I spun up this little guy:

<a href="/images/atmega8-bare-bones-board.jpg">
<img src="/images/atmega8-bare-bones-board.jpg" style="width:300px;">
</a>

(the one on the right)

It's essentially a blank canvas.  In addition to breaking out all of the
Atmega8 headers, there's a 16MHz external crystal oscillator, some basic
power circuitry, and an AVR SPI programming header.

I populated two or three of these things and have used them in a bunch of
projects over the years.  It's been such a solid and useful little board
that I thought I'd share it here.  Here's the schematic:

<a href="/images/bare_bones_atmega8_schematic.png">
<img src="/images/bare_bones_atmega8_schematic.png" style="width:300px;">
</a>

The full Eagle source is
[available on GitHub](https://github.com/mgalgs/atmega8-bare-bones).
