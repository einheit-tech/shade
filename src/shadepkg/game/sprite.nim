import
  node,
  spritesheet,
  ../math/mathutils

when defined(spriteBounds):
  import ../render/color

export node, spritesheet, mathutils

type
  Sprite* = ref object
    spritesheet: Spritesheet
    frameCoords*: IVector
    offset*: Vector

proc initSprite*(
  sprite: Sprite,
  image: Image,
  hframes,
  vframes: int,
  frameCoords: IVector = IVECTOR_ZERO
) =
  sprite.spritesheet = newSpritesheet(image, hframes, vframes)
  sprite.frameCoords = frameCoords

proc newSprite*(
  image: Image,
  hframes: int = 1,
  vframes: int = 1,
  frameCoords: IVector = IVECTOR_ZERO
): Sprite =
  result = Sprite()
  initSprite(result, image, hframes, vframes, frameCoords)

Sprite.render:
  translate(ctx, this.offset.x, this.offset.y):
    # `blit` renders the image centered at the given location.
    blit(
      this.spritesheet.image,
      this.spritesheet[this.frameCoords].addr,
      ctx,
      0,
      0
    )

    when defined(spriteBounds):
      ## Renders the bounds or sprites.
      let rect = this.spritesheet[this.frameCoords]
      ctx.rectangle(
        -rect.w / 2,
        -rect.h / 2,
        rect.w / 2,
        rect.h / 2,
        BLUE
      )

