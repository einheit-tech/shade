import
  entity,
  spritesheet,
  ../math/mathutils

when defined(spriteBounds):
  import ../render/color

export entity, spritesheet, mathutils

type
  Sprite* = ref object
    spritesheet*: Spritesheet
    frameCoords*: IVector
    offset*: Vector
    scale*: Vector
    # Rotation in degrees (clockwise).
    rotation*: float

proc initSprite*(
  sprite: Sprite,
  image: Image,
  hframes,
  vframes: int,
  frameCoords: IVector = IVECTOR_ZERO
) =
  # TODO: Flyweight pattern for spritesheets.
  sprite.spritesheet = newSpritesheet(image, hframes, vframes)
  sprite.frameCoords = frameCoords
  sprite.scale = VECTOR_ONE

proc newSprite*(
  image: Image,
  hframes: int = 1,
  vframes: int = 1,
  frameCoords: IVector = IVECTOR_ZERO
): Sprite =
  result = Sprite()
  initSprite(result, image, hframes, vframes, frameCoords)

template numFrames*(this: Sprite): int =
  this.spritesheet.rows * this.spritesheet.cols

proc `alpha=`*(this: Sprite, alpha: CompletionRatio) =
  this.spritesheet.image.setRGBA(
    uint8.high,
    uint8.high,
    uint8.high,
    uint8(float(uint8.high) * alpha)
  )

proc size*(this: Sprite): Vector =
  this.spritesheet.spriteSize

Sprite.render:
  # `blit` renders the image centered at the given location.
  blitTransform(
    this.spritesheet.image,
    this.spritesheet[this.frameCoords].addr,
    ctx,
    offsetX + (this.scale.x * this.offset.x),
    offsetY + (this.scale.y * this.offset.y),
    this.rotation,
    this.scale.x,
    this.scale.y
  )

  when defined(spriteBounds):
    ## Renders the bounds or sprites.
    let rect = this.spritesheet[this.frameCoords]
    # TODO: Needs to be offset
    ctx.rectangle(
      -rect.w / 2,
      -rect.h / 2,
      rect.w / 2,
      rect.h / 2,
      BLUE
    )

