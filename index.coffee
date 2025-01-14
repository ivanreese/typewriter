# CONFIG
ss = 4 # How many pixels per CSS unit? Higher values = bigger output image

# We assume that the provided glyph images will be an atlas of characters arranged in this pattern
atlasLayout = "!\"#$%_&'()*+ 1234567890-= QWERTYUIOP¼ qwertyuiop½ ASDFGHJKL:@ asdfghjkl;¢ ZXCVBNM,.? zxcvbnm,./".split /\s/

# Top left corner in atlas
sx = 65
sy = 40

# Offset between chars in atlas
ox = 217
oy = 300

# Size to draw each char
dw = 140 / 4
dh = 210 / 4

# Position to draw the next char
dx = dy = 0

# These adjust the spacing between chars.
tracking = -16
leading = -8

# The atlases are slightly skewed, so this tries to compensate
skew = 170

# Initialize the drawing canvas
elm = document.querySelector "canvas"
ctx = elm.getContext "2d"

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

# RENDERING #######################################################################################

render = ()->
  text = textarea.value
  keys = text.split ""

  tracking = +trackingInput.value || -16
  leading = +leadingInput.value || -8

  # The width of the drawing canvas is based solely on the width input
  lineWidth = +widthInput.value || 300
  w = (dw + tracking) * lineWidth

  # We do a layout-only pass so we can measure the height of the canvas
  dx = dy = 0 # Reset the cursor position to the top left
  drawKey k, w, false for k in keys
  h = dy + dh # Measure the height of the canvas

  # Now that we've got the width and height, we can update the canvas
  elm.width = w * ss
  elm.height = h * ss
  ctx.scale ss, ss # Have to set this every time we resize the canvas.

  # Chars have a lot of white space around them, which can overlap if we use
  # negative tracking/leading, so this compensates for that.
  ctx.globalCompositeOperation = "darken" # Have to set this every time we resize the canvas.
  ctx.fillStyle = "#fff"
  ctx.fillRect 0, 0, w, h

  # Finally, we can draw all the chars
  dx = dy = 0 # Reset the cursor position to the top left (again)
  drawKey k, w, true for k in keys

drawKey = (k, w, draw)->
  if dx is 0 and k is " " then return # Don't draw a space at the beginning of a line
  if k is "\n" then return newline()
  if k is " " then return adv w

  [x, y] = getCharPosInAtlas k
  return unless x? and y?

  x = sx + ox * x
  y = sy + oy * y

  # Compensate for the atlases being slightly tilted
  y -= x / skew

  if draw then ctx.drawImage img, x, y, 210, 315, dx, dy, dw, dh

  adv w

# Advance the cursor by one space
adv = (w)->
  dx += dw + tracking
  if dx + dw >= w then newline()

# Advance the cursor to the beginning of the next line
newline = ()->
  dx = 0
  dy += dh + leading

# INPUT HANDLING ##################################################################################

# Get the various control elements
widthInput = null
trackingInput = null
leadingInput = null
fontInput = null
textarea = null
downloadBtn = null

do ()->
  (widthInput = document.querySelector "#width").oninput = ()->
    localStorage.setItem "width", widthInput.value
    render()
  if width = localStorage.getItem "width" then widthInput.value = width

  (trackingInput = document.querySelector "#tracking").oninput = ()->
    localStorage.setItem "tracking", trackingInput.value
    render()
  if tracking = localStorage.getItem "tracking" then trackingInput.value = tracking

  (leadingInput = document.querySelector "#leading").oninput = ()->
    localStorage.setItem "leading", leadingInput.value
    render()
  if leading = localStorage.getItem "leading" then leadingInput.value = leading

  (fontInput = document.querySelector "#font").oninput = ()->
    localStorage.setItem "font", fontInput.value
    loadImg fontInput.value
  if font = localStorage.getItem "font" then fontInput.value = font

  (textarea = document.querySelector "textarea").oninput = ()->
    localStorage.setItem "text", textarea.value
    render()
  if text = localStorage.getItem "text" then textarea.value = text

  (downloadBtn = document.querySelector "#download").onclick = ()->
    link = document.createElement "a"
    link.href = elm.toDataURL()
    link.download = "typewriter.png"
    link.click()
    link.remove()
