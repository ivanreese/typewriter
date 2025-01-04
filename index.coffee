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

getGridPos = (c)->
  for row, y in chars
    x = row.indexOf c
    return [x, y] if x isnt -1
  [null, null]

img = new Image()
img.src = "regular.jpg"
img.onload = ()-> render()

loadImg = (src)->
  newImg = new Image()
  newImg.src = src
  newImg.onload = ()->
    img = newImg
    render()

sx = 65
sy = 40
ox = 217
oy = 300

p = 0

dx = p
dy = p
dw = 140 / 4
dh = 210 / 4

newline = ()->
  dx = p
  dy += dh+p

adv = ()->
  dx += dw+p
  if dx + dw >= w then newline()

keys = ["_"]

window.addEventListener "keydown", (e)->
  if e.ctrlKey
    if e.key is "1" then loadImg "light.jpg"
    if e.key is "2" then loadImg "regular.jpg"
    if e.key is "3" then loadImg "double.jpg"
    return

  keys.pop()

  if e.key is "Backspace"
    keys.pop()
  else
    keys.push e.key

  keys.push "_"

  render()

render = ()->
  dx = p
  dy = p
  ctx.clearRect 0, 0, w, h

  drawKey k for k in keys

drawKey = (k)->
  if k is "Enter" then return newline()
  if k is " " then return adv()

  [x, y] = getGridPos k
  return unless x? and y?

  x = sx + ox * x
  y = sy + oy * y

  ctx.drawImage img, x, y, 210, 315, dx, dy, dw, dh

  adv()


render()