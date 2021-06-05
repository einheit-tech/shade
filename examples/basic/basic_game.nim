import ../../src/shade

const
  width = 800
  height = 600

var game: Game = newGame("Basic Example Game", width, height)
let layer = newLayer()
game.scene.addLayer layer

type CustomEntity = ref object of Entity

proc newCustomEntity(): CustomEntity =
  CustomEntity(
    flags: {loUpdate, loRender},
    material: NULL,
    center: VEC2_ZERO
  )

method update*(this: CustomEntity, deltaTime: float) =
  this.translate vec2(1, 1)

method render*(this: CustomEntity, ctx: Context) =
  ctx.fillStyle = rgba(255, 0, 0, 255)
  let size = vec2(100, 100)
  ctx.fillRect(rect(this.center, size))

layer.add(newCustomEntity())

game.start()

