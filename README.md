# Mediator

I sit between your domain model and the cold, cruel world.

## TODO

* Nested collections or objects, like `r.array :albums` or `r.obj
  :contact` in the example above. Should create a new mediator stack
  for each entry in the collection but somehow mark the current
  mediator as the parent.

* For `r.ids`, just value.map(&:id). Should check for `_ids` shortcut
  first though, but only if an explicit value isn't provided.

* Nested collections should always exist in rendered output even if
  they're empty or missing.

* Benchmarks and micro-opts, esp. around object allocation.

* Decent doco.

## License (MIT)

Copyright 2011-2012 Audiosocket (tech@audiosocket.com)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
