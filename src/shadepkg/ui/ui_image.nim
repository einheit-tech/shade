import sdl2_nim/sdl_gpu
import
  ui,
  ../math/mathutils,
  ../math/aabb

type
  UIImageObj = object of UIComponent
    image*: Image
    imageAlignHorizontal*: Alignment
    imageAlignVertical*: Alignment

  UIImage* = ref UIImageObj

proc `=destroy`(this: var UIImageObj) =
  if this.image != nil:
    freeImage(this.image)

proc newUIImage*(image: Image): UIImage =
  result = UIImage(image: image)
  initUIComponent(UIComponent result)

method postRender*(this: UIImage, ctx: Target, renderBounds: AABB) =
  procCall postRender(UIComponent this, ctx, renderBounds)

  let
    scaleX = renderBounds.width / float(this.image.w) 
    scaleY = renderBounds.height / float(this.image.h)
    minScalar = min(1.0, min(scaleX, scaleY))

  let x = case this.imageAlignHorizontal:
    of Start:
      renderBounds.left + float(this.image.w) * minScalar / 2
    of Center:
      renderBounds.center.x
    of End:
      renderBounds.right - float(this.image.w) * minScalar / 2

  let y = case this.imageAlignVertical:
    of Start:
      renderBounds.top + float(this.image.h) * minScalar / 2
    of Center:
      renderBounds.center.y
    of End:
      renderBounds.bottom - float(this.image.h) * minScalar / 2

  blitScale(this.image, nil, ctx, x, y, minScalar, minScalar)

