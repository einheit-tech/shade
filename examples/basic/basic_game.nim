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
    velocity: vec2(100, 100),
    flags: {loUpdate, loRender},
    center: VEC2_ZERO
  )

render(CustomEntity, Entity):
  ctx.fillStyle = rgba(255, 0, 0, 255)
  let size = vec2(100, 100)
  ctx.fillRect(rect(this.center, size))

layer.add(newCustomEntity())

game.start()

