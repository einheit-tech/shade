from sdl2_nim/sdl import Color

import ../math/mathutils

export Color

proc newColor*(r, g, b: uint8, a: uint8 = 255): Color =
  return Color(r: r, g: g, b: b, a: a)

func lerp*(startValue, endValue: Color, completionRatio: CompletionRatio): Color =
  return newColor(
    uint8 lerp(float startValue.r, float endValue.r, completionRatio),
    uint8 lerp(float startValue.g, float endValue.g, completionRatio),
    uint8 lerp(float startValue.b, float endValue.b, completionRatio),
    uint8 lerp(float startValue.a, float endValue.a, completionRatio)
  )

const
  TRANSPARENT* = Color()
  WHITE* = newColor(255, 255, 255)
  BLACK* = newColor(0, 0, 0)
  RED* = newColor(255, 0, 0)
  GREEN* = newColor(0, 255, 0)
  BLUE* = newColor(0, 0, 255)
  PURPLE* = newColor(255, 0, 255)
  ORANGE* = newColor(255, 165, 0)

