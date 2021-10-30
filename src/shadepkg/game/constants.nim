import ../math/mathutils

const
  meterToPixelScalar* = 32.0
  pixelToMeterScalar* = 1 / meterToPixelScalar
  VEC2_METERS_TO_PIXELS* = dvec2(meterToPixelScalar, meterToPixelScalar)
  VEC2_PIXELS_TO_METERS* = dvec2(pixelToMeterScalar, pixelToMeterScalar)

