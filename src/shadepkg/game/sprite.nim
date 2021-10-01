import
  entity,
  spritesheet,
  ../math/mathutils

export entity, spritesheet, mathutils

type Sprite* = ref object of Entity
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
  initEntity(Entity(sprite), flags)
  sprite.spritesheet = newSpritesheet(image, hframes, vframes)
  sprite.frameCoords = frameCoords

proc newSprite*(
  image: Image,
  hframes,
  vframes: int,
  flags: set[LayerObjectFlags] = {loUpdate, loRender},
  frameCoords: IVec2 = IVEC2_ZERO
): Sprite =
  result = Sprite()
  initSprite(result, image, hframes, vframes, flags, frameCoords)

render(Sprite, Entity):
  blit(
    this.spritesheet.image,
    this.spritesheet[this.frameCoords].addr,
    ctx,
    cfloat 0,
    cfloat 0
  )

  if callback != nil:
    callback()

