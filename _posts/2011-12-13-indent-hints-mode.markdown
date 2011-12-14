---
layout: post
title: Indent Hints Mode
permalink: /projects/indent-hints-mode.html
category: projects
tags: [emacs, elisp]
---

##### Tabs vs Spaces #####

Should you use tabs or spaces to indent your code? Well, if you're
writing new code on a new project, then obviously you get to
pick. However, if you're adding to some existing code the answer is:
*whatever was already there*. Since inspecting whitespace and toggling
your text editor's settings is tedious at best I created an Emacs
minor mode to do it for you. The purpose of the mode is summed up best
by the README:

<blockquote>
<p>
If you jump into a file that uses tabs for indentation, you shall
continue using tabs for indentation. If you jump into a file that uses
spaces for indentation, you shall continue using spaces for
indentation. That's the idea.
</p>
</blockquote>

Grab the code on GitHub:
[https://github.com/mgalgs/indent-hints-mode](https://github.com/mgalgs/indent-hints-mode)
