import sdl2_nim/sdl_gpu
import
  ui,
  ../math/mathutils,
  ../math/aabb

type
  ImageFit* = enum
    ## For details, see: https://developer.mozilla.org/en-US/docs/Web/CSS/object-fit
    Contain
    Cover
    Fill
  UIImageObj = object of UIComponent
    image*: Image
    imageAlignHorizontal*: Alignment
    imageAlignVertical*: Alignment
    imageFit*: ImageFit

  UIImage* = ref UIImageObj

proc `=destroy`(this: var UIImageObj) =
  if this.image != nil:
    freeImage(this.image)

proc newUIImage*(image: Image): UIImage =
  result = UIImage(image: image)
  initUIComponent(UIComponent result)

template renderImageFitContain(this: UIImage, ctx: Target, renderBounds: AABB): tuple[scaleX, scaleY: float] =
  let
    scaleX = renderBounds.width / float(this.image.w) 
    scaleY = renderBounds.height / float(this.image.h)
    minScalar = min(1.0, min(scaleX, scaleY))

  (minScalar, minScalar)

template renderImageFitCover(this: UIImage, ctx: Target, renderBounds: AABB): tuple[scaleX, scaleY: float] =
  let
    scaleX = renderBounds.width / float(this.image.w) 
    scaleY = renderBounds.height / float(this.image.h)
    maxScalar = max(1.0, max(scaleX, scaleY))

  (maxScalar, maxScalar)

template renderImageFitFill(this: UIImage, ctx: Target, renderBounds: AABB): tuple[scaleX, scaleY: float] =
  (
    renderBounds.width / float(this.image.w),
    renderBounds.height / float(this.image.h)
  )

method postRender*(this: UIImage, ctx: Target, renderBounds: AABB) =
  procCall postRender(UIComponent this, ctx, renderBounds)

  let (scaleX, scaleY) =
    case this.imageFit:
      of Contain:
        this.renderImageFitContain(ctx, renderBounds)
      of Cover:
        this.renderImageFitCover(ctx, renderBounds)
      of Fill:
        this.renderImageFitFill(ctx, renderBounds)

  let x = case this.imageAlignHorizontal:
    of Start:
      renderBounds.left + float(this.image.w) * scaleX / 2
    of Center:
      renderBounds.center.x
    of End:
      renderBounds.right - float(this.image.w) * scaleX / 2

  let y = case this.imageAlignVertical:
    of Start:
      renderBounds.top + float(this.image.h) * scaleY / 2
    of Center:
      renderBounds.center.y
    of End:
      renderBounds.bottom - float(this.image.h) * scaleY / 2

  blitScale(this.image, nil, ctx, x, y, scaleX, scaleY)

