import sdl2_nim/sdl_gpu
import
  ui_component,
  ../math/vector2,
  ../math/aabb,
  ../images/imageatlas

export ui_component, vector2

type
  ImageFit* = enum
    ## For details, see: https://developer.mozilla.org/en-US/docs/Web/CSS/object-fit
    Contain
    Cover
    Fill

  ImageAlignment* = enum
    Start
    Center
    End

  UIImageObj = object of UIComponent
    image*: Image
    imageAlignHorizontal*: ImageAlignment
    imageAlignVertical*: ImageAlignment
    imageFit*: ImageFit
    scale: Vector

  UIImage* = ref UIImageObj

proc `scale=`*(this: UIImage, scale: Vector)
method getImageViewport*(this: UIImage): Rect {.base.}

proc `=destroy`(this: var UIImageObj) =
  if this.image != nil:
    freeImage(this.image)

proc initUIImage*(uiImage: UIImage, image: Image, scale: Vector = VECTOR_ONE) =
  initUIComponent(UIComponent uiImage)
  uiImage.image = image
  uiImage.scale = scale
  `scale=`(uiImage, scale)

proc newUIImage*(image: Image): UIImage =
  result = UIImage()
  initUIImage(result, image)

proc newUIImage*(imagePath: string, imageFilter: Filter = FILTER_LINEAR): UIImage =
  let (_, image) = Images.loadImage(imagePath)
  image.setImageFilter(imageFilter)
  return newUIImage(image)

proc scale*(this: UIImage): Vector =
  return this.scale

proc `scale=`*(this: UIImage, scale: Vector) =
  this.scale = scale
  if this.image != nil:
    let imageViewport = this.getImageViewport()
    this.width = float(imageViewport.w) * this.scale.x
    this.height = float(imageViewport.h) * this.scale.y

method getImageWidth*(this: UIImage): float {.base.} =
  ## Gets the unscaled width of the image.
  return float this.image.w

method getImageHeight*(this: UIImage): float {.base.} =
  ## Gets the unscaled height of the image.
  return float this.image.h

method getImageViewport*(this: UIImage): Rect {.base.} =
  return (cfloat 0, cfloat 0, cfloat this.image.w, cfloat this.image.h)

template getImageFitContainScalar(
  this: UIImage,
  ctx: Target,
  contentWidth: float,
  contentHeight: float
): tuple[scaleX, scaleY: float] =
  let
    scaleX = contentWidth / this.getImageWidth()
    scaleY = contentHeight / this.getImageHeight()
    minScalar = min(1.0, min(scaleX, scaleY))

  (this.scale.x * minScalar, this.scale.y * minScalar)

template getImageFitCoverScalar(
  this: UIImage,
  ctx: Target,
  contentWidth: float,
  contentHeight: float
): tuple[scaleX, scaleY: float] =
  let
    scaleX = contentWidth / this.getImageWidth() 
    scaleY = contentHeight / this.getImageHeight()
    maxScalar = max(1.0, max(scaleX, scaleY))

  (this.scale.x * maxScalar, this.scale.y * maxScalar)

template getImageFitFillScalar(
  this: UIImage,
  ctx: Target,
  contentWidth: float,
  contentHeight: float
): tuple[scaleX, scaleY: float] =
  (
    this.scale.x * contentWidth / this.getImageWidth(),
    this.scale.y * contentHeight / this.getImageHeight()
  )

method preRender*(this: UIImage, ctx: Target, clippedRenderBounds: AABB) =
  procCall preRender(UIComponent this, ctx, clippedRenderBounds)

  let (scaleX, scaleY) =
    case this.imageFit:
      of Contain:
        this.getImageFitContainScalar(ctx, clippedRenderBounds.width, clippedRenderBounds.height)
      of Cover:
        this.getImageFitCoverScalar(ctx, clippedRenderBounds.width, clippedRenderBounds.height)
      of Fill:
        this.getImageFitFillScalar(ctx, clippedRenderBounds.width, clippedRenderBounds.height)

  let x = case this.imageAlignHorizontal:
    of Start:
      clippedRenderBounds.left + this.getImageWidth() * scaleX / 2
    of Center:
      clippedRenderBounds.center.x
    of End:
      clippedRenderBounds.right - this.getImageWidth() * scaleX / 2

  let y = case this.imageAlignVertical:
    of Start:
      clippedRenderBounds.top + this.getImageHeight() * scaleY / 2
    of Center:
      clippedRenderBounds.center.y
    of End:
      clippedRenderBounds.bottom - this.getImageHeight() * scaleY / 2

  let viewport = this.getImageViewport()
  blitScale(this.image, viewport.unsafeAddr, ctx, x, y, scaleX, scaleY)

