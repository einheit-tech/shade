import
  ui_image,
  ../game/sprite

type
  UISprite* = ref object of UIImage
    sprite*: Sprite

proc newUISprite*(sprite: Sprite): UISprite =
  result = UISprite(sprite: sprite)
  initUIImage(UIImage result, sprite.spritesheet.image)
  result.width = sprite.size.x
  result.height = sprite.size.y

method getImageWidth*(this: UISprite): float =
  return this.sprite.size.x

method getImageHeight*(this: UISprite): float =
  return this.sprite.size.y

method getImageViewport*(this: UISprite): Rect =
  return this.sprite.spritesheet[this.sprite.frameCoords]

