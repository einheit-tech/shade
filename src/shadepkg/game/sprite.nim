import
  node,
  spritesheet,
  ../math/mathutils

type Sprite* = ref object of Node
  spritesheet: Spritesheet
  frameCoords*: IVec2

proc initSprite*(sprite: Sprite, spritesheet: Spritesheet, frameCoords: IVec2 = IVEC2_ZERO) =
  initNode(Node(sprite), {loRender})
  sprite.spritesheet = spritesheet
  sprite.frameCoords = frameCoords

proc newSprite*(spritesheet: Spritesheet, frameCoords: IVec2 = IVEC2_ZERO): Sprite =
  result = Sprite()
  initSprite(result, spritesheet, frameCoords)

render(Sprite, Node):
  let currentFrameImage = this.spritesheet[this.frameCoords]
  ctx.image.draw(currentFrameImage)

  if callback != nil:
    callback()

