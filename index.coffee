# Calculate the scale factor that'll get us to the output DPI we want
charactersPerInch = 11 # this is based on the actual typewriter
linesPerInch = 8 # ROUGHLY — this is based on the glyph scan Todd sent me
atlasDPI = 1200 # ROUGHLY — this is based on the glyph scan Todd sent me
outputDPI = 600 # You can change this to whatever value you want, and everything Just Works™
scale = outputDPI / atlasDPI

# The width of the canvas — controlled by the ruler
lineWidth = 64 # this works out to A5 paper width

# These create empty space…
margin = 6 # left and right — measure in character widths
padding = 3 # on the top and bottom — measure in line heights

# ATLAS ###########################################################################################

# We assume that the provided glyph images will be an atlas of characters arranged in this pattern
# We also assume that the characters in this atlas have a single space between them
atlasLayout = "!\"#$%_&'()*+ 1234567890-= QWERTYUIOP¼ qwertyuiop½ ASDFGHJKL:@ asdfghjkl;¢ ZXCVBNM,.? zxcvbnm,./".split /\s/

# Top left corner in atlas — just eyeball it
sx = 75
sy = 110

# Size of glyphs in the atlas
gw = atlasDPI / charactersPerInch
gh = atlasDPI / linesPerInch

# What's the default line height (ie: line height of "1"), relative to a glyph
lh = gh * 1.5

# Shift the vertical alignment a bit so that it looks better
verticalAlign = gh * .4

# How much extra space around the glyph should we include when copying the glyph from the atlas to the canvas?
# When this is zero, glyphs sometimes get cut off. If it's too big, you'll see bits of neighbouring glyphs.
pad = gw * 0.4

# The atlases are slightly rotated, so this tries to compensate
skew = 1.3

# This function returns the x,y pixel position within the atlas for a given character, or null if the character isn't in the atlas.
# The characters in the atlas have a single space between them, and the lines are double-spaced, so we multiply positions by 2 in both directions.
getGlyphPosInAtlas = (c)->
  for row, y in atlasLayout
    x = row.indexOf c
    if x isnt -1
      px = sx + (2 * x * gw)
      py = sy + (2 * y * gh) - x * skew # Compensate for the atlases being slightly tilted
      return [px, py]
  [null, null]

variant = ""
atlas = "regular"

# This image stores the currently-loaded glyph atlas
atlasImg = null

loadAtlas = ()->
  src = "#{atlas}#{variant}"
  src = "regular-red" if src is "double-red"

  atlasImg = new Image()
  atlasImg.src = "glyphs/#{src}.png"
  atlasImg.onload = ()->
    render()
    document.querySelector("section").style.opacity = 1

# RENDERING #######################################################################################

# Initialize the drawing canvases
elm = document.querySelector "canvas.text"
ctx = elm.getContext "2d"

rulerElm = document.querySelector "canvas.ruler"
rulerCtx = rulerElm.getContext "2d"

# Position to draw the next char
cx = margin
cy = padding
endOfLine = false

render = ()->
  text = textarea.value
  words = text.split " "

  # The width of the drawing canvas is based on the ruler
  w = gw * lineWidth

  # We first do a layout-only pass so we can measure the height of the canvas
  cx = margin # Reset the cursor position to the top left
  cy = padding
  endOfLine = false
  drawWord i, words, false for _, i in words
  h = (cy + 1 + padding) * lh # Measure the height of the canvas

  # Before we resize the canvas, check if we're scrolled to the bottom.
  oldHeight = elm.height

  # Now that we've got the width and height, we can update the canvas
  # elm.style.width = Math.min(w / 10, 1200)
  elm.width = w * scale
  elm.height = h * scale
  ctx.scale scale, scale # Have to set this every time we resize the canvas.

  if oldHeight < elm.height
    document.body.scrollBy top: elm.height - oldHeight

  # The extra padding on chars means they overlap, so this allows them to overlap nicely
  ctx.globalCompositeOperation = "darken" # Have to set this every time we resize the canvas.

  ctx.fillStyle = "#fff"
  ctx.fillRect 0, 0, w, h

  # For debugging glyph layout
  ctx.fillStyle = "#f001"

  # rulerElm.style.width = Math.min(w / 10, 1200)
  shrinkX = rulerElm.offsetWidth / rulerElm.width
  shrinkY = rulerElm.offsetHeight / rulerElm.height

  dpr = window.devicePixelRatio
  rulerElm.width = rulerElm.offsetWidth * dpr
  rulerElm.height = rulerElm.offsetHeight * dpr
  rulerCtx.clearRect 0, 0, w, 80
  # rulerCtx.scale 1/shrinkX, 1/shrinkY

  # Finally, we can draw all the chars
  cx = margin # Reset the cursor position to the top left (again)
  cy = padding
  endOfLine = false
  drawWord i, words, true for _, i in words

  rulerStep = gw * scale * (rulerElm.width - 2) / elm.width

  rulerCtx.beginPath()
  px = margin * rulerStep + 2
  rulerCtx.roundRect px|0, -12, (lineWidth - margin*2) * rulerStep, 80, 10
  rulerCtx.strokeStyle = "hsl(18, 4%, 19%)"
  rulerCtx.lineWidth = 4
  rulerCtx.stroke()

  for i in [0..lineWidth]
    continue if margin is i or i is lineWidth - margin
    rulerCtx.fillStyle = if i % 10 is 0 then "hsl(18, 2%, 55%)" else "hsl(18, 2%, 45%)"
    rulerCtx.fillStyle = "hsl(18, 4%, 25%)" unless margin < i < lineWidth - margin
    height = if i % 10 is 0 then 35 else if i % 5 is 0 then 25 else 15
    px = i * rulerStep
    rulerCtx.fillRect px|0, 0, 4, height

  # console.log shrink

drawWord = (i, words, draw)->
  word = words[i]
  lastWord = i is words.length-1

  if word.length is 0
    adv() if not endOfLine and not lastWord
    return

  # First, figure out if there's room on the line for this word
  if cx + word.length >= lineWidth - margin
    newline()

  for k, j in word
    endOfLine = false

    if k is "\n"
      newline()
      continue

    [gx, gy] = getGlyphPosInAtlas k
    [gx, gy] = getGlyphPosInAtlas "*" unless gx? and gy?

    # Draw the glyph at these pixel coords
    px = cx * gw
    py = cy * lh + verticalAlign

    if draw
      ctx.drawImage atlasImg, gx - pad, gy - pad, gw + pad*2, gh + pad*2, px - pad, py - pad, gw + pad*2, gh + pad*2

      # Uncomment to debug glyph layout
      # ctx.fillRect px - pad, py - pad, gw-1 + pad*2, gh-1 + pad*2 # this is the glyph without padding

    adv() # advance to the next letter

  adv() if cx isnt margin and not lastWord # advance one extra space for the next word

# Advance the cursor by one space
adv = ()->
  return if endOfLine
  cx++
  if cx >= lineWidth - margin
    endOfLine = true
    newline()

# Advance the cursor to the beginning of the next line
newline = ()->
  cx = margin
  cy++

# INPUT HANDLING ##################################################################################

$ = (q)-> document.querySelector q

# Get the various control elements
textarea = null
downloadBtn = null

setAtlas = (v)->
  btn.classList.remove "active" for name, btn of btns
  btns[v].classList.add "active"
  atlas = v
  loadAtlas()

ctrls = {
  lineWidth: (elm)-> updateRuler lineWidth = +elm.value + margin * 2
  margin: (elm)-> updateRuler margin = +elm.value
}
Object.entries(ctrls).map ([n, cb])->
  e = ctrls[n] = $ "#" + n
  e.oninput = e.onchange = ()-> cb e

btns = {}
["regular", "light", "double"].map (n)-> (btns[n] = $ "#" + n).onclick = ()-> setAtlas save "atlas", n
($ ".toggle").onclick = (e)->
  variant = if e.target.checked then "-red" else ""
  save "variant", variant
  loadAtlas()

load = (name, def)-> localStorage.getItem(name) ? save name, def
save = (name, val)-> localStorage.setItem(name, val) ? val

updateRuler = ()->
  margin = Math.max 1, margin
  lineWidth = Math.max lineWidth, margin * 2 + 1
  save "margin", margin
  save "lineWidth", lineWidth
  ctrls.margin.value = margin
  ctrls.lineWidth.value = lineWidth - margin * 2
  pxPerChar = rulerElm.offsetWidth / lineWidth
  ctrls.margin.style.left = pxPerChar * margin/2
  ctrls.margin.style.width = margin.toString().length + ".25em"
  render()

do ()->
  (textarea = $ "textarea").oninput = ()->
    save "text", textarea.value
    render()
  textarea.value = load "text", ""

  ($ "#reset").onclick = ()->
    save "text", textarea.value = ""
    margin = 6
    lineWidth = 64
    updateRuler()
    ($ ".toggle").checked = false
    variant = ""
    setAtlas "regular"

  ($ "#download").onclick = ()->
    link = document.createElement "a"
    link.href = elm.toDataURL()
    link.download = "typewriter.png"
    link.click()
    link.remove()

rulerElm.onpointerdown = (e)->
  start = e.clientX
  window.onpointerup = ()-> window.onpointermove = null

  pxPerChar = rulerElm.offsetWidth / lineWidth
  isMargin = e.offsetX / pxPerChar <= margin

  window.onpointermove = (e)->
    pxPerChar = rulerElm.offsetWidth / lineWidth
    charDragDist = (e.clientX - start) / pxPerChar
    return if Math.abs(charDragDist) < 1

    if isMargin
      margin += Math.sign charDragDist
    else
      lineWidth -= Math.sign charDragDist
    start += pxPerChar * Math.sign charDragDist
    updateRuler()

variant = load "variant", ""
setAtlas load "atlas", "regular"
($ ".toggle").checked = variant isnt ""
margin = load "margin", 6
lineWidth = load "lineWidth", 64
updateRuler()
