import
  std/monotimes,
  os,
  math,
  pixie,
  opengl,
  staticglfw

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
  ctx: Context
  window: Window
  bgColor: ColorRGBX

proc update*(this: Game, deltaTime: float)
proc render*(this: Game, ctx: Context)

proc newGame*(
  title: string,
  gameWidth, gameHeight: int,
  scene: Scene = newScene(),
  bgColor: ColorRGBX = rgba(0, 0, 0, 255)
): Game =
  if init() == staticglfw.FALSE:
    quit("Failed to initialize GLFW.")

  let screen = newImage(gameWidth, gameHeight)
  result = Game(
    ctx: newContext(screen),
    scene: scene,
    bgColor: bgColor
  )

  # Create a window
  windowHint(RESIZABLE, false.cint)
  result.window = createWindow(gameWidth.cint, gameHeight.cint, title, nil, nil)

  # Create the rendering context
  makeContextCurrent(result.window)
  loadExtensions()

  # Allocate a texture and bind it
  var dataPtr = result.ctx.image.data[0].addr
  glTexImage2D(
    GL_TEXTURE_2D, 0, 3,
    GLsizei gameWidth,
    GLsizei gameHeight,
    0,
    GL_RGBA,
    GL_UNSIGNED_BYTE,
    dataPtr
  )
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)
  glEnable(GL_TEXTURE_2D)

template ctx*(this: Game): Context = this.ctx
template scene*(this: Game): Scene = this.scene
template `scene=`*(this: Game, scene: Scene) = this.scene = scene

proc loop(this: Game) =
  var
    startTimeNanos = getMonoTime().ticks
    elapsedNanos: int64 = 0

  while this.window.windowShouldClose != staticglfw.TRUE:
    pollEvents()
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

  this.window.destroyWindow()
  terminate()

proc start*(this: Game) =
  # TODO: Make this async so it's non-blocking
  this.loop()

proc stop*(this: Game) =
  this.window.setWindowShouldClose(staticglfw.TRUE)

proc update*(this: Game, deltaTime: float) =
  if this.scene != nil:
    this.scene.update(deltaTime)

proc render(this: Game, ctx: Context) =
  if this.scene == nil:
    return

  this.scene.render(ctx)

  # Update texture with new pixels from surface
  var dataPtr = ctx.image.data[0].addr
  glTexSubImage2D(
    GL_TEXTURE_2D, 0, 0, 0,
    GLsizei ctx.image.width,
    GLsizei ctx.image.height,
    GL_RGBA,
    GL_UNSIGNED_BYTE,
    dataPtr
  )

  # Draw a quad over the whole screen
  glClear(GL_COLOR_BUFFER_BIT)
  glBegin(GL_QUADS)
  glTexCoord2d(0.0, 0.0); glVertex2d(-1.0, +1.0)
  glTexCoord2d(1.0, 0.0); glVertex2d(+1.0, +1.0)
  glTexCoord2d(1.0, 1.0); glVertex2d(+1.0, -1.0)
  glTexCoord2d(0.0, 1.0); glVertex2d(-1.0, -1.0)
  glEnd()

  swapBuffers(this.window)

  ctx.image.fill(this.bgColor)

