elm = document.querySelector "canvas"
ctx = elm.getContext "2d"

w = elm.offsetWidth
h = elm.offsetHeight

dpi = window.devicePixelRatio
elm.width = w * dpi
elm.height = h * dpi

ctx.scale(dpi, dpi)

chars = "!\"#$%_&'()*+
1234567890-=
QWERTYUIOP¼
qwertyuiop½
ASDFGHJKL:@
asdfghjkl;¢
ZXCVBNM,.?
zxcvbnm,./".split /\s/

console.log chars

getGridPos = (c)->
  for row, y in chars
    x = row.indexOf c
    return [x, y] if x isnt -1
  [null, null]

img = new Image()
img.src = "/regular.jpg"

sx = 65
sy = 40
ox = 217
oy = 300

p = 0

dx = p
dy = p
dw = 140 / 2
dh = 210 / 2

newline = ()->
  dx = p
  dy += dh+p

adv = ()->
  dx += dw+p
  if dx + dw >= w then newline()

window.onkeydown = (e)->
  if e.key is "Enter" then return newline()
  if e.key is " " then return adv()

  [x, y] = getGridPos e.key
  return unless x? and y?

  x = sx + ox * x
  y = sy + oy * y

  ctx.drawImage img, x, y, 210, 315, dx, dy, dw, dh

  adv()