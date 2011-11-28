---
layout: post
title: Hello, World!
---
This is my first post from GitHub pages.

Seems pretty sweetening powder.

##### How I decided which pygments style to use for this blog:
{% highlight bash %}
for i in $(python2 -c 'from pygments.styles import get_all_styles;print "\n".join(list(get_all_styles()))'); do
    echo "testing $i";
    pygmentize -S $i -f html > syntax.css;
    read;
done
{% endhighlight %}

I ended up going with the `pastie` theme for
[pygments](http://pygments.org/).

##### Some more syntax highlighting tests:
###### elisp
{% highlight scheme %}
(defun fill-out-to-column (&optional width fill-char)
  "Insert FILL-CHAR at the end of the current line until the line
  is WIDTH columns wide. WIDTH defaults to 80 and FILL-CHAR
  defaults to a space (i.e. ?\s)"
  (interactive)
  (end-of-line)
  ;; some defaults
  (if (not width) (setq width 80))
  (if (not fill-char) (setq fill-char ?\s))
  (let ((n (- width (current-column))))
    (if (> n 0)
        (insert-char fill-char n))))
{% endhighlight %}

###### python
{% highlight python %}
def hello():
  print "hi"
{% endhighlight %}

###### c++
{% highlight c++ %}
class Thing {
public:
  int stuff();
};

int Thing::stuff()
{
  return 42;
}
{% endhighlight %}

###### c
{% highlight c %}
int main(int argc, char *argv[])
{
    printf("hello, world!\n");
    return 0;
}
{% endhighlight %}

###### haskell
{% highlight haskell %}
-- Type annotation (optional)
fib :: Int -> Integer
 
-- Point-free style
fib = (fibs !!)
    where fibs = 0 : scanl (+) 1 fibs
 
-- Explicit
fib n = fibs !! n
    where fibs = 0 : scanl (+) 1 fibs
 
-- With a similar idea, using zipWith
fib n = fibs !! n
    where fibs = 0 : 1 : zipWith (+) fibs (tail fibs)
 
-- Using a generator function
fib n = fibs (0,1) !! n
    where fibs (a,b) = a : fibs (b,a+b)
{% endhighlight %}
