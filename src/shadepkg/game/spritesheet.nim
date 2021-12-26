import
  ../render/render,
  ../math/mathutils

type Spritesheet* = ref object
  sheetImage: Image
  spriteRects: seq[Rect]
  cols: int
  rows: int

proc loadSprites*(this: Spritesheet)

template image*(this: Spritesheet): Image =
  this.sheetImage

proc newSpritesheet*(sheetImage: Image, cols, rows: int): Spritesheet =
  ## Creates a new Spritesheet.
  ## The individual sprite images are not created here,
  ## but need to be loaded by invoking loadSprites.
  result = Spritesheet(
    sheetImage: sheetImage,
    cols: cols,
    rows: rows,
    spriteRects: newSeq[Rect](rows * cols)
  )
  result.loadSprites()

proc loadSprites*(this: Spritesheet) =
  ## Loads all individual sprite images from the sprite sheet.
  let
    spriteWidth = this.sheetImage.w.float / this.cols.float
    spriteHeight = this.sheetImage.h.float / this.rows.float

  for row in (0..<this.rows):
    for col in (0..<this.cols):
      this.spriteRects[col + row * this.cols] =
        (
          cfloat(col.float * spriteWidth),
          cfloat(row.float * spriteHeight),
          cfloat(spriteWidth),
          cfloat(spriteHeight)
        )

template rows*(this: Spritesheet): int =
  this.rows

template cols*(this: Spritesheet): int =
  this.cols

template `[]`*(this: Spritesheet, index: int): Rect =
  this.spriteRects[index]

template `[]`*(this: Spritesheet, x, y: int): Rect =
  ## Gets the sprite image at (x, y).
  this.spriteRects[x + y * this.cols]

template `[]`*(this: Spritesheet, coord: IVector): Rect =
  ## Gets the sprite image at (x, y).
  this[coord.x, coord.y]

