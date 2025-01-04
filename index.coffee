# Initialize the drawing canvas
elm = document.querySelector "canvas"
ctx = elm.getContext "2d"

# Size the drawing canvas, accounting for DPI
w = elm.offsetWidth
h = elm.offsetHeight
dpi = window.devicePixelRatio
elm.width = w * dpi
elm.height = h * dpi
ctx.scale dpi, dpi

# Chars have a lot of white space around them,
# which can overlap if we use negative tracking/leading,
# so this compensates for that.
ctx.globalCompositeOperation = "darken"

# We assume that the provided glyph images will be an atlas of characters arranged in this pattern
atlasLayout = "!\"#$%_&'()*+ 1234567890-= QWERTYUIOP¼ qwertyuiop½ ASDFGHJKL:@ asdfghjkl;¢ ZXCVBNM,.? zxcvbnm,./".split /\s/

# This function returns the x,y position within the atlas for a given character, or null if the character isn't in the atlas
getCharPosInAtlas = (c)->
  for row, y in atlasLayout
    x = row.indexOf c
    if x isnt -1 then return [x, y]
  [null, null]

# This image stores the currently-loaded glyph atlas
img = null

loadImg = (src)->
  img = new Image()
  img.src = "glyphs/" + src + ".png"
  img.onload = ()-> render()

# By default, load the regular weight
loadImg "regular"

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

# These adjust the spacing between chars
tracking = -10
leading = -20

# Advance the cursor to the beginning of the next line
newline = ()->
  dx = p
  dy += dh + p + leading

# Advance the cursor by one space
adv = ()->
  dx += dw + p + tracking
  if dx + dw >= w then newline()

# Store all the keys that have been typed, so we can re-render from scratch every time.
# The _ is the cursor.
keys = ["_"]


window.addEventListener "keydown", (e)->
  if e.metaKey and e.key is "v"
    e.preventDefault()
    text = await navigator.clipboard.readText()
    if text?.length > 0
      keys = text.split("")
    return render()

  # Change font
  if e.ctrlKey
    if e.key is "1" then loadImg "light"
    if e.key is "2" then loadImg "regular"
    if e.key is "3" then loadImg "double"
    if e.key is "4" then loadImg "light-red"
    if e.key is "5" then loadImg "regular-red"
    return

  # Remove the cursor
  keys.pop() if keys.at(-1) is "_"

  # Update the array of keys that have been typed
  if e.key is "Backspace"
    keys.pop()
  else if e.key is "Enter"
    keys.push "\n"
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
  if k is "\n" then return newline()
  if k is " " then return adv()

  [x, y] = getCharPosInAtlas k
  return unless x? and y?

  x = sx + ox * x
  y = sy + oy * y

  ctx.drawImage img, x, y, 210, 315, dx, dy, dw, dh

  adv()
