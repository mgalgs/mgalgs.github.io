---
layout: post
title: Halloween Pi (and stuff)
tags: [electronics, hardware, raspberry-pi, avr, atmega8]
---

I had so much fun
[shooting trick-or-treaters with silly string](https://www.youtube.com/watch?v=N_VGspit7Xk)
last year that I decided to up the ante this year with an "Evil Bouncey
Ball Shooter".  Before getting into the nitty gritty, here's the final
product in action at our local "Trunk or Treat":

<iframe width="560" height="315" src="https://www.youtube.com/embed/al_0_y3Uv1I?rel=0" frameborder="0" allowfullscreen></iframe>

Building this thing was quite an adventure.  So much so that I decided it
merited a quick blog post.  So without further ado, let's dive in...

# The Brains

Here's the full schematic:

<a href="/images/halloween-2015-circuit.png">
<img src="/images/halloween-2015-circuit.png" style="width:300px;">
</a>

As you can see from the schematic below, there are actually two separate
CPUs in this project: a Raspberry Pi and an Atmega8.  Why two brains?  Why
not!?  Actually, originally I had planned on doing the whole thing with
just the Pi, but it turns out that the Raspberry Pi A only has one PWM
channel, and that's needed to run the audio headphone jack, but I needed
PWM to control my servo as well.  So that's why I had to throw the Atmega8
in there.  Kind of a shame, but I have them lying around, so why not.

# The Mechanics

As you can tell, mechanical design is *not* my strong suit.  It took
[several](/images/buggy-ball-feeder.jpg) revisions of the ball feeder
design until I got something reliable.

I think the neatest part of the mechanical design ended up being the ball
rate limiting mechanism:

<iframe width="560" height="315" src="https://www.youtube.com/embed/jkJooS4Y_Vc?rel=0" frameborder="0" allowfullscreen></iframe>

Yes, that *is* a hex key serving as a ball stopper.  Best use I've ever
found for a hex key...

# The Circuit

It's been a few years since I've done any microelectronics so I needed a
bit of a refresher on MOSFETs...  I was having issues getting
[my solenoid](http://www.amazon.com/gp/product/B00B300KQK?psc=1&redirect=true&ref_=oh_aui_detailpage_o00_s00)
to actuate with a MOSFET driven by one of my Pi's GPIOs:

<a href="/images/buggy-solenoid-circuit.png">
<img src="/images/buggy-solenoid-circuit.png" style="width:300px;">
</a>

The issue was that
[the MOSFET I was using](http://www.kitsandparts.com/IRF510.pdf) actually
needs 10V to be switched on.  I mistakenly thought that the gate-source
threshold voltage (which is 2-4V for this MOSFET) was all I needed to
switch the MOSFET on.  Luckily, we have
[electronics.stackexchange.com](http://electronics.stackexchange.com/)
these days and the fine folks over there
[set me straight](http://electronics.stackexchange.com/questions/197120/solenoid-doesnt-actuate-when-driven-through-mosfet/)
in no time.  What I needed was a MOSFET driver between the GPIO and the
MOSFET.  After throwing [this guy](http://amzn.com/B00DK2C7YM) in there I
was in business.  I also could have just switched to a logic-level MOSFET.

# I2C for Inter Chip Communication

The Raspberry Pi and Atmega8 talk to each other over I2C.

  - [AVR initialization code](https://github.com/mgalgs/halloween-2015/blob/eaa55592d4fcbc568860973247ca2cd6ac5cac35/firmware/main.c#L62)
  - [Pi initialization code](https://github.com/mgalgs/halloween-2015/blob/eaa55592d4fcbc568860973247ca2cd6ac5cac35/main.py#L58)
  - [AVR communication code](https://github.com/mgalgs/halloween-2015/blob/eaa55592d4fcbc568860973247ca2cd6ac5cac35/firmware/main.c#L173)
  - [Pi communication code](https://github.com/mgalgs/halloween-2015/blob/eaa55592d4fcbc568860973247ca2cd6ac5cac35/main.py#L80)

# Servo Control

The servo is controlled with a standard servo control signal (5-10% duty
cycle PWM wave @50Hz).  As I mentioned earlier, this had to be done on the
Atmega8 since doing it on the Pi conflicted with its audio output.

  - [AVR servo initialization code](https://github.com/mgalgs/halloween-2015/blob/eaa55592d4fcbc568860973247ca2cd6ac5cac35/firmware/main.c#L32)
  - [AVR servo angle-setting code](https://github.com/mgalgs/halloween-2015/blob/eaa55592d4fcbc568860973247ca2cd6ac5cac35/firmware/main.c#L62)

I was seeing erratic behavior of my servo that I finally debugged to being
an incorrect clock fuse settings on the Atmega8.  I used my
[bus pirate](http://dangerousprototypes.com/bus-pirate-manual/) to measure
the frequency of the PWM signal and noticed it was exactly half the
frequency I expected.  After rechecking my math and counter settings I
finally determined my Atmega8's clock must be messed up.  Sure enough, my
clock fuse settings were incorrect.
[Here](https://github.com/mgalgs/halloween-2015/commit/1c1d02e116a69597d31ddfd92860a179c201a2d0)'s
the patch to fix them.  I freaking love my bus pirate...

# Distance Sensor

I'm using
[this](http://www.amazon.com/gp/product/B00E0NXTJW?psc=1&redirect=true&ref_=oh_aui_detailpage_o06_s00)
distance sensor, connected to the Pi, to determine how far away the
unsuspecting trick-or-treaters are.  The way you use this sensor is by
requesting a ping by asserting the *echo trigger* pin, then watching how
long the *echo* pin stays high.  That time is equal to the time it took for
the sensor to get its own ping back.  Multiply that by the speed of sound
(and divide by two due to the fact that the ping traveled to the subject
*and back*) and we're in business.  The (somewhat hacky) code that does
this is on the Pi
[here](https://github.com/mgalgs/halloween-2015/blob/eaa55592d4fcbc568860973247ca2cd6ac5cac35/main.py#L112).

See also: [the datasheet](http://e-radionica.com/productdata/HCSR04.pdf).

# Bootup

I wrote
[a simple `systemd` service file](https://github.com/mgalgs/halloween-2015/blob/eaa55592d4fcbc568860973247ca2cd6ac5cac35/halloween-py.service)
to get things running as soon as the Pi boots up.  Works like a charm, and
even lets me see all my `mpg123` subprocesses in a nice little tree view.
Sorry, `systemd` haters :).

# Source Code

The code is all [on GitHub](https://github.com/mgalgs/halloween-2015).

# Handy Resources

Here's a list of some handy resources I used for this project:

  - [Bus Pirate](http://dangerousprototypes.com/bus-pirate-manual/)
  - [electronics.stackexchange.com](http://electronics.stackexchange.com/)
  - [Amazing Raspberry Pi Pinout](https://pi.gadgetoid.com/pinout)
