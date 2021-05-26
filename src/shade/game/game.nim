import
  std/monotimes,
  os,
  math,
  pixie

import
  scene

const
  # TODO: Get hz of monitor or allow this to be configurable.
  fps = 60
  oneBillion = 1000000000
  oneMillion = 1000000
  sleepNanos = round(oneBillion / fps).int

type Game* = object
  scene: Scene
  running: bool
  ctx: Context

proc update*(this: Game, deltaTime: float)
proc render*(this: Game, ctx: Context)

proc newGame*(gameWidth, gameHeight: int, scene: Scene = newScene()): Game =
  let screen = newImage(gameWidth, gameHeight)
  Game(
    running: false,
    ctx: newContext(screen),
    scene: newScene()
  )

template isRunning*(this: Game): bool = this.running
template ctx*(this: Game): Context = this.ctx
template `scene=`*(this: Game, scene: Scene) = this.scene = scene

proc loop(this: Game) =
  var
    startTimeNanos = getMonoTime().ticks
    elapsedNanos: int64 = 0

  while this.isRunning:
    # Determine elapsed time in seconds
    let deltaTime: float = elapsedNanos.float64 / oneBillion.float64
    this.update(deltaTime)
    this.render(this.ctx)

    # Calculate sleep time
    elapsedNanos = getMonoTime().ticks - startTimeNanos
    let sleepMilis =
      round(max(0, sleepNanos - elapsedNanos).float64 / oneMillion.float64).int
    sleep(sleepMilis)

    let time = getMonoTime().ticks
    elapsedNanos = time - startTimeNanos
    startTimeNanos = time

proc start*(this: var Game) =
  this.running = true
  this.loop()

proc stop*(this: var Game) =
  this.running = false

proc update*(this: Game, deltaTime: float) =
  if this.scene != nil:
    this.scene.update(deltaTime)

proc render*(this: Game, ctx: Context) =
  if this.scene != nil:
    this.scene.render(ctx)

