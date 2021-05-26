import
  std/monotimes,
  os,
  math

import scene

const
  # TODO: Get hz of monitor or allow this to be configurable.
  fps = 60
  oneBillion = 1000000000
  oneMillion = 1000000
  sleepNanos = round(oneBillion / fps).int

type Game* = object
  scene: Scene
  running: bool

proc update*(this: Game, deltaTime: float)
proc render*(this: Game)

proc newGame*(scene: Scene): Game =
  Game(
    scene: scene,
    running: false
  )

template isRunning*(this: Game): bool = this.running
template `scene=`*(this: Game, scene: Scene) = this.scene = scene

proc loop(this: Game) =
  var
    startTimeNanos = getMonoTime().ticks
    elapsedNanos: int64 = 0

  while this.isRunning:
    # Determine elapsed time in seconds
    let deltaTime: float = elapsedNanos.float64 / oneBillion.float64
    this.update(deltaTime)
    this.render()

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

proc render*(this: Game) =
  if this.scene != nil:
    this.scene.render()

