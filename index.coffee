elm = document.querySelector "canvas"
ctx = elm.getContext "2d"

w = elm.offsetWidth
h = elm.offsetHeight

dpi = window.devicePixelRatio
elm.width = w * dpi
elm.height = h * dpi

ctx.scale(dpi, dpi)

chars = "!\"#$%_&'()*+ 1234567890-= QWERTYUIOP¼ qwertyuiop½ ASDFGHJKL:@ asdfghjkl;¢ ZXCVBNM,.? zxcvbnm,./".split /\s/

getGridPos = (c)->
  for row, y in chars
    x = row.indexOf c
    return [x, y] if x isnt -1
  [null, null]

img = null

loadImg = (src)->
  img = new Image()
  img.src = src
  img.onload = ()-> render()

loadImg "regular.jpg"

# Top left corner in img
sx = 65
sy = 40

# Offset between chars in img
ox = 217
oy = 300

# Extra padding between rendered chars
p = 0

# Position to draw the next char
dx = p
dy = p

# Size to draw the next char
dw = 140 / 4
dh = 210 / 4

# Advance the cursor to the beginning of the next line
newline = ()->
  dx = p
  dy += dh+p

# Advance the cursor by one space
adv = ()->
  dx += dw+p
  if dx + dw >= w then newline()

# Store all the keys that have been typed, so we can re-render from scratch every time.
# The _ is the cursor.
keys = ["_"]

window.addEventListener "keydown", (e)->

  # Change font
  if e.ctrlKey
    if e.key is "1" then loadImg "light.jpg"
    if e.key is "2" then loadImg "regular.jpg"
    if e.key is "3" then loadImg "double.jpg"
    return

  # Remove the cursor
  keys.pop()

  # Update the array of keys that have been typed
  if e.key is "Backspace"
    keys.pop()
  else
    keys.push e.key

  # Add the cursor
  keys.push "_"

  render()

render = ()->
  # Reset — we'll re-draw the whole thing every time
  ctx.clearRect 0, 0, w, h
  dx = p
  dy = p

  # Draw all the keys
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
