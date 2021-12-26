import ../math/mathutils

const
  meterToPixelScalar* = 32.0
  pixelToMeterScalar* = 1 / meterToPixelScalar
  VEC2_METERS_TO_PIXELS* = vector(meterToPixelScalar, meterToPixelScalar)
  VEC2_PIXELS_TO_METERS* = vector(pixelToMeterScalar, pixelToMeterScalar)

