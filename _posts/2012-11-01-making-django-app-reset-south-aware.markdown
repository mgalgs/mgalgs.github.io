---
layout: post
title: Making Django App Reset South-Aware
tags: [django]
---

Today I needed to reset an app in a Django site I'm working on. The
problem is that I'm using
[South](http://south.readthedocs.org/en/latest/) on this app to track
database schema migrations. Since I'm using South, I can't just do:

	python manage.py reset myapp

because that doesn't reset the South migration history. One
[solution](http://balzerg.blogspot.com/2012/09/django-app-reset-with-south.html)
I found floating around on the web got me pretty close, but it also
coalesced all of my existing migrations into a single "initial"
migration, which I didn't want.

All I need to do to accomplish what I want (reset an app while
maintaining existing migrations) is:

	python manage.py sqlclear myapp | python manage.py dbshell
	# ...edit south.models.MigrationHistory...
	python manage.py migrate myapp

<h4>The Management Command</h4>

To make things a little easier, I've packaged the first two steps up
into a Django management command so that I can reset a South app like
so:

	python manage.py south_clear myapp
	python manage.py migrate myapp

Here's the management command:

<script src="https://gist.github.com/3998773.js"> </script>

Drop this in a `management/commands` directory (if you've never done
that before, see
[here](https://docs.djangoproject.com/en/dev/howto/custom-management-commands/))
and you're good to go!
