import
  node,
  spritesheet,
  ../math/mathutils

when defined(spriteBounds):
  import ../render/color

export node, spritesheet, mathutils

type Sprite* = ref object of Node
  spritesheet: Spritesheet
  frameCoords*: IVec2

proc initSprite*(
  sprite: Sprite,
  image: Image,
  hframes,
  vframes: int,
  flags: set[LayerObjectFlags] = {loUpdate, loRender},
  frameCoords: IVec2 = IVEC2_ZERO
) =
  initNode(Node(sprite), flags)
  sprite.spritesheet = newSpritesheet(image, hframes, vframes)
  sprite.frameCoords = frameCoords

proc newSprite*(
  image: Image,
  hframes: int = 1,
  vframes: int = 1,
  flags: set[LayerObjectFlags] = {loUpdate, loRender},
  frameCoords: IVec2 = IVEC2_ZERO
): Sprite =
  result = Sprite()
  initSprite(result, image, hframes, vframes, flags, frameCoords)

render(Sprite, Node):
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
      RED
    )

  if callback != nil:
    callback()

