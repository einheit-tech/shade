import
  std/monotimes

export monotimes

template time*(body: untyped): float =
  let startTimeNanos = getMonoTime().ticks
  body
  let endTimeNanos = getMonoTime().ticks
  float(endTimeNanos - startTimeNanos) / 1000000
