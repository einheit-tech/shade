from sdl2_nim/sdl import Color

export Color

proc newColor*(r, g, b, a: uint8): Color =
  return Color(r: r, g: g, b: b, a: a)

const
  WHITE* = newColor(255, 255, 255, 255)
  BLACK* = newColor(0, 0, 0, 255)
  RED* = newColor(255, 0, 0, 255)
  GREEN* = newColor(0, 255, 0, 255)
  BLUE* = newColor(0, 0, 255, 255)

