import
  sdl2_nim/[sdl_gpu],
  tables

type
  # See https://vladar4.github.io/sdl2_nim/sdl_gpu.html#loadImage%2Ccstring
  # TODO: http://www.dinomage.com/2015/01/sdl_gpu-simple-tutorial/
  ImageAtlas* = ref object
    images: Table[int, Image]
    nextTextureId: int

proc newImageAtlas(): ImageAtlas =
  return ImageAtlas()

# Singleton
var Images* = newImageAtlas()

proc registerImage(this: ImageAtlas, image: Image): int =
  result = this.nextTextureId
  this.images[result] = image
  this.nextTextureId.inc
  return result

proc loadImage*(this: ImageAtlas, imagePath: string): tuple[id: int, image: Image] =
  result.image = loadImage(imagePath)
  if result.image == nil:
    raise newException(Exception, "Failed to load image: " & imagePath)

  result.id = this.registerImage(result.image)

template `[]`*(this: ImageAtlas, imageID: int): Image =
  this.images[imageID]

proc free*(this: ImageAtlas, imageID: int) =
  freeImage this.images[imageID]
  this.images.del(imageID)

proc freeAll*(this: ImageAtlas) =
  for id in this.images.keys():
    this.free(id)
  this.images.clear()
  this.nextTextureId = 0

