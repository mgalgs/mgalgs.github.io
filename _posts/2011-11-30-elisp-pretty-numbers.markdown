---
layout: post
title: Elisp Pretty Numbers
---

Here are some elisp functions I cooked up today to make looking at
numbers a little more convenient.

First, a function to add a thousands separator to a (possibly floating
point) number:

{% highlight scheme %}
(defun my-thousands-separate (num)
  "Formats the (possibly floating point) number with a thousands
separator."
  (let* ((nstr (number-to-string num))
         (dot-ind (string-match "\\." nstr))
         (nstr-no-decimal (if dot-ind
                               (substring nstr 0 dot-ind)
                             nstr))
         (nrest (if dot-ind
                    (substring nstr dot-ind)
                  nil))
         (pretty nil)
         (cnt 0))
    (dolist (c (reverse (append nstr-no-decimal nil)))
      (if (and (zerop (% cnt 3)) (> cnt 0))
          (setq pretty (cons ?, pretty)))
      (setq pretty (cons c pretty))
      (setq cnt (1+ cnt)))
    (concat pretty nrest)))
{% endhighlight %}

Usage:

{% highlight scheme %}
(my-thousands-separate 4324.32)
  ==> "4,324.32"
(my-thousands-separate 42)
  ==> "42"
(my-thousands-separate 929344324432444.0)
  ==> "929,344,324,432,444.0"
{% endhighlight %}

With that function in hand, I wrote a little convenience function for
looking at numbers:

{% highlight scheme %}
(defun my-prettify-number (n)
  "Prints a number to the minibuffer in a few delicious
formats. If `current-word' is a number, that's what is used,
otherwise we prompt the user."
  (interactive
   (let ((default
           (save-excursion
             (skip-chars-backward "0-9")
             (if (looking-at "[-+]?\\([0-9]*\.\\)?[0-9]+")
                 (string-to-number (current-word))
               (read-number "Number: ")))))
     (list default)))
  (let ((nstr (number-to-string n))
        (npretty (my-thousands-separate n)))
    (message "%s | %g | %d | %s" npretty n n nstr)))
{% endhighlight %}

Usage: put your point on a number and do `M-x my-prettify-number`.
