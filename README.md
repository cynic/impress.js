impresst.js
============

This is a fork of [impress.js](https://github.com/bartaz/impress.js), the excellent presentation framework created by Bartek Szopka.  This fork has a few small changes that might be particularly useful for teachers, and some other changes because, well, why not?  If you don't know how to use impress.js, then learn how to do so by taking a look at the original repo, and then come back here :).

Differences/Features
---------

Some differences from how impress.js does it:

- I like to use [CoffeeScript](http://coffeescript.org), so impresst.js is actually impresst.coffee.  You'll need to compile it with CoffeeScript to get the JS out.  ``coffee -c impresst.coffee``, if you haven't ever done that before.
- Impress.js makes you specify x, y, and z coordinates for each step.  Impresst.js automagically lays things out in a randomised grid, with a bit of z-coordinate-munging to make transitions look extra-snazzy ;).
- Impress.js supports a lot of keys: tab, page-up, page-down, down-arrow, left-arrow, space etc etc.  These are used for navigation.  Impresst.js supports left-arrow and right-arrow, and that's all.  That's because I expect people to click on links to get to other slides.
- Tying in with the clicking-on-links idea, there's a 'back' button on most impresst.js slides.

Some additional features:

- CSS3 tooltips!
- ... which are used to allow the author (that's you, hopefully) to reference articles and other material.
- ... and which are also used for footnotes.

See `sample.html` for the details.

LICENSE
---------

In compliance with the original source, this is released under the MIT and GPL (version 3 or later) Licenses.


