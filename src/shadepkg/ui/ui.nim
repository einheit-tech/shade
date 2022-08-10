import sdl2_nim/sdl_gpu
from ../math/mathutils import CompletionRatio
import
  ../math/vector2,
  ../math/aabb,
  ../render/color

export
  CompletionRatio,
  Vector,
  Color,
  Target

type
  Size* = Vector
  PixelSize* = Size
  RatioSize* = object
    x: CompletionRatio
    y: CompletionRatio

  Insets* = AABB

  Alignment* = enum
    Start
    Center
    End
  
  StackDirection* = enum
    Vertical
    Horizontal

  ValidationStatus* = enum
    Valid
    Invalid
    InvalidChild

  UIComponent* = ref object of RootObj
    parent: UIComponent
    children: seq[UIComponent]
    width*: float
    height*: float
    margin*: Insets
    padding*: Insets
    alignHorizontal*: Alignment
    alignVertical*: Alignment
    stackDirection*: StackDirection
    layoutValidationStatus: ValidationStatus
    bounds: AABB
    backgroundColor*: Color
    clipToBounds*: bool

  UI* = object
    root*: UIComponent

# UIComponent

proc parent*(this: UIComponent): lent UIComponent =
  return this.parent

proc layoutValidationStatus*(this: UIComponent): lent ValidationStatus =
  return this.layoutValidationStatus

proc bounds*(this: UIComponent): lent AABB =
  return this.bounds

method update*(this: UIComponent, deltaTime: float) {.base.} =
  discard

method preRender*(this: UIComponent, ctx: Target, width, height: float) {.base.} =
  discard

method postRender*(this: UIComponent, ctx: Target, width, height: float) {.base.} =
  discard

# UI

proc update*(this: UI, deltaTime: float) =
  discard

proc preRender*(this: UI, ctx: Target, width, height: float) =
  discard

proc postRender*(this: UI, ctx: Target, width, height: float) =
  discard

