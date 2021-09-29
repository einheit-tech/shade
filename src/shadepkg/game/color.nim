from sdl2_nim/sdl import Color

proc newColor*(r, g, b, a: uint8): Color =
  return Color(r: r, g: g, b: b, a: a)

const 
  COLOR_BLACK* = newColor(0, 0, 0, 255)
  COLOR_WHITE* = newColor(255, 255, 255, 255)

