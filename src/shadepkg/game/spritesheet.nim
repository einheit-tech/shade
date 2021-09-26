import pixie

type Spritesheet* = ref object
  sheetImage: Image
  spriteImages: seq[Image]
  rows: int
  cols: int

proc newSpritesheet*(filepath: string, rows, cols: int): Spritesheet =
  ## Creates a new Spritesheet with the given file name.
  ## The individual sprite images are not created here,
  ## but need to be loaded by invoking loadSprites.
  return Spritesheet(
    sheetImage: readImage(filepath),
    rows: rows,
    cols: cols,
    spriteImages: newSeq[Image](rows * cols)
  )

proc loadSprites*(this: Spritesheet) =
  ## Loads all individual sprite images from the sprite sheet.
  let
    spriteWidth = this.sheetImage.width div this.cols
    spriteHeight = this.sheetImage.height div this.rows

  for row in (0..<this.rows):
    for col in (0..<this.cols):
      let spriteImage = this.sheetImage.subImage(
        col * spriteWidth,
        row * spriteHeight,
        spriteWidth,
        spriteHeight
      )
      this.spriteImages[col + row * this.cols] = spriteImage

template rows*(this: Spritesheet): int =
  this.rows

template cols*(this: Spritesheet): int =
  this.cols

template `[]`*(this: Spritesheet, i: int): Image =
  this.spriteImages[i]

template `[]`*(this: Spritesheet, x, y: int): Image =
  ## Gets the sprite image at (x, y).
  this[x + y * this.cols]

template `[]`*(this: Spritesheet, coord: IVec2): Image =
  ## Gets the sprite image at (x, y).
  this[coord.x, coord.y]

