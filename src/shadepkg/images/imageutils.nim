import sdl2_nim/[sdl_gpu]
import shade

proc createTransformedImage*(
  image: Image,
  x: float = 0,
  y: float = 0,
  rotationDegrees: float = 0,
  scaleX: float = 1,
  scaleY: float = 1
): Image =
  # TODO: This doesn't work yet, don't know why.
  result = createImage(image.w, image.h, Format_RGBA)
  blitTransform(
    image,
    nil,
    result.target,
    x,
    y,
    rotationDegrees,
    scaleX,
    scaleY
  )
