import pixie

type
  SpriteSheet* = object
    image: Image
    rows: int
    columns: int

proc newSpriteSheet*(image: Image, rows, columns: int): SpriteSheet =
  result.image = image
  result.rows = rows
  result.columns = columns

