from sdl2_nim/sdl import Color

export Color

proc newColor*(r, g, b: uint8, a: uint8 = 255): Color =
  return Color(r: r, g: g, b: b, a: a)

const
  WHITE* = newColor(255, 255, 255)
  BLACK* = newColor(0, 0, 0)
  RED* = newColor(255, 0, 0)
  GREEN* = newColor(0, 255, 0)
  BLUE* = newColor(0, 0, 255)
  PURPLE* = newColor(255, 0, 255)
  ORANGE* = newColor(255, 165, 0)

