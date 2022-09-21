import sdl2_nim/sdl_gpu
import
  ui_component,
  ../math/mathutils,
  ../math/aabb,
  ../images/imageatlas

export ui_component

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

method preRender*(this: UIImage, ctx: Target) =
  procCall preRender(UIComponent this, ctx)

  let
    renderContentArea = aabb(
      this.bounds.left + this.borderWidth,
      this.bounds.top + this.borderWidth,
      this.bounds.right - this.borderWidth,
      this.bounds.bottom - this.borderWidth
    )

  let (scaleX, scaleY) =
    case this.imageFit:
      of Contain:
        this.getImageFitContainScalar(ctx, renderContentArea.width, renderContentArea.height)
      of Cover:
        this.getImageFitCoverScalar(ctx, renderContentArea.width, renderContentArea.height)
      of Fill:
        this.getImageFitFillScalar(ctx, renderContentArea.width, renderContentArea.height)

  let x = case this.imageAlignHorizontal:
    of Start:
      renderContentArea.left + this.getImageWidth() * scaleX / 2
    of Center:
      renderContentArea.center.x
    of End:
      renderContentArea.right - this.getImageWidth() * scaleX / 2

  let y = case this.imageAlignVertical:
    of Start:
      renderContentArea.top + this.getImageHeight() * scaleY / 2
    of Center:
      renderContentArea.center.y
    of End:
      renderContentArea.bottom - this.getImageHeight() * scaleY / 2

  let viewport = this.getImageViewport()
  blitScale(this.image, viewport.unsafeAddr, ctx, x, y, scaleX, scaleY)
