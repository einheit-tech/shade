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
  frameCoords: IVec2 = IVEC2_ZERO
) =
  initEntity(Entity(sprite), {loRender, loUpdate})
  sprite.spritesheet = newSpritesheet(image, hframes, vframes)
  sprite.frameCoords = frameCoords

proc newSprite*(
  image: Image,
  hframes,
  vframes: int,
  frameCoords: IVec2 = IVEC2_ZERO
): Sprite =
  result = Sprite()
  initSprite(result, image, hframes, vframes, frameCoords)

render(Sprite, Node):
  var spriteRect = this.spritesheet[this.frameCoords]

  # TODO: Revise math now that we render from the center of images.
  let 
    translationX = cfloat -this.center.x
    translationY = cfloat -this.center.y

  translate(translationX, translationY, cfloat 0)

  blit(this.spritesheet.image, spriteRect.addr, ctx, cfloat 0, cfloat 0)

  if callback != nil:
    callback()

  translate(-translationX, -translationY, cfloat 0)

