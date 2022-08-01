import std/monotimes

export monotimes

const ONE_BILLION = 1_000_000_000

template measureRuntime*(body: untyped): float =
  ## Reports the runtime in seconds.
  let startTimeNanos = getMonoTime().ticks
  body
  let endTimeNanos = getMonoTime().ticks
  float(endTimeNanos - startTimeNanos) / ONE_BILLION
