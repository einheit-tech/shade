import
  sdl2_nim/sdl_ttf,
  tables

type
  FontAtlas* = ref object
    fonts: Table[int, Font]
    nextFontID: int

proc newFontAtlas(): FontAtlas =
  if sdl_ttf.wasInit() == 0:
    if sdl_ttf.init() != 0:
      raise newException(Exception, "Failed to init TTF engine: " & $sdl_ttf.getError())
  return FontAtlas()

# Singleton
var Fonts* = newFontAtlas()

proc registerFont(this: FontAtlas, font: Font): int =
  result = this.nextFontID
  this.fonts[result] = font
  this.nextFontID.inc

proc loadFont*(this: FontAtlas, fontPath: string, size: int): tuple[id: int, font: Font] =
  result.font = openFont(fontPath, size)
  if result.font == nil:
    raise newException(Exception, "Failed to load font: " & fontPath)
  result.id = this.registerFont(result.font)

template `[]`*(this: FontAtlas, fontID: int): Font =
  this.fonts[fontID]

proc free*(this: FontAtlas, fontID: int) =
  closeFont(this.fonts[fontID])
  this.fonts.del(fontID)

proc freeAll*(this: FontAtlas) =
  for id in this.fonts.keys():
    this.free(id)
  this.fonts.clear()
  this.nextFontID = 0

