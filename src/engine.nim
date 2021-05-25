import
  math,
  opengl,
  pixie,
  staticglfw

proc render(image: pixie.Image)

let
  w: int32 = 256
  h: int32 = 256

var
  screen = newImage(w, h)
  ctx = newContext(screen)
  frameCount = 0
  window: Window

proc display() =
  ## Called every frame by main while loop
  render(ctx.image)
 
  # update texture with new pixels from surface
  var dataPtr = ctx.image.data[0].addr
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, GLsizei w, GLsizei h, GL_RGBA, GL_UNSIGNED_BYTE, dataPtr)

  # draw a quad over the whole screen
  glClear(GL_COLOR_BUFFER_BIT)
  glBegin(GL_QUADS)
  glTexCoord2d(0.0, 0.0); glVertex2d(-1.0, +1.0)
  glTexCoord2d(1.0, 0.0); glVertex2d(+1.0, +1.0)
  glTexCoord2d(1.0, 1.0); glVertex2d(+1.0, -1.0)
  glTexCoord2d(0.0, 1.0); glVertex2d(-1.0, -1.0)
  glEnd()

  inc frameCount
  swapBuffers(window)

if init() == 0:
  quit("Failed to Initialize GLFW.")

windowHint(RESIZABLE, false.cint)
window = createWindow(w.cint, h.cint, "GLFW/Pixie", nil, nil)

makeContextCurrent(window)
loadExtensions()

# allocate a texture and bind it
var dataPtr = ctx.image.data[0].addr
glTexImage2D(GL_TEXTURE_2D, 0, 3, GLsizei w, GLsizei h, 0, GL_RGBA,
    GL_UNSIGNED_BYTE, dataPtr)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)
glEnable(GL_TEXTURE_2D)

proc render(image: pixie.Image) =
  var font = readFont("./fonts/JetBrainsMono-Regular.ttf")
  font.size = 20
  let text = "Typesetting is the arrangement and composition of text in graphic design and publishing in both digital and traditional medias."
  image.fill(rgba(255, 255, 255, 255))
  image.fillText(font.typeset(text, bounds = vec2(180, 180)), vec2(10, 10))

while windowShouldClose(window) != 1:
  pollEvents()
  display()

