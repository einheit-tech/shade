import nico

const spritesDirectory = "sprites/"

var spritesheetCount: int = 0

proc loadSpritesheet*(filename: string, sw, sh: int = 8): int =
  ## Loads the spritesheet with the given file name.
  ## Each sprite is of size sw, sh.
  ## The function returns the index of the spritesheet.
  result = spritesheetCount
  loadSpritesheet(spritesheetCount, spritesDirectory & filename, sw, sh)
  spritesheetCount.inc

