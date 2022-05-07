import std/[algorithm, math]

const
  ONE_BILLION = 1000000000
  DELTA_WINDOW_CAP = 60

type
  RefreshRateCalculator* = ref object
    refreshRate: int
    deltaWindow: seq[float]

template refreshRate*(this: RefreshRateCalculator): int =
  this.refreshRate

proc median(l, r: int): int =
  return l + ((r - l) div 2)

proc q13(values: seq[float]): tuple[q1: float, q3: float] =
  let sortedValues = sorted(values)
  let n = len(sortedValues)
  let mid = median(0, n)
  let q1 = sortedValues[median(0, mid)]
  let q3 = sortedValues[median(mid + 1, n)]
  return (q1, q3)

proc iqr(q13: tuple[q1: float, q3: float]): float =
  return q13.q3 - q13.q1

proc outlier(value: float, q13: tuple[q1: float, q3: float]): bool =
  let i = 1.5 * iqr(q13)
  let lower = q13.q1 - i
  let upper = q13.q3 + i
  return value < lower or value > upper

proc calcRefreshRate*(this: RefreshRateCalculator, elapsedNanos: int64) =
  ## Calculates the refresh rate based on elapsed time between frames.
  ## This function will set `this.refreshRate` after a number of frames,
  ## so it should be called until `this.refreshRate` is not == 0.
  let realDeltaTime = float(elapsedNanos) / float(ONE_BILLION)
  # Push new sample
  this.deltaWindow.add(realDeltaTime)
  # Only start using delta window after it's filled up
  if len(this.deltaWindow) == DELTA_WINDOW_CAP:
    # Prune outliers
    var newDeltaWindow: seq[float] = newSeqOfCap[float](DELTA_WINDOW_CAP)
    let deltaWindowQ13 = q13(this.deltaWindow)
    var foundOutlier = false
    for sample in this.deltaWindow:
      if outlier(sample, deltaWindowQ13):
        foundOutlier = true
      else:
        newDeltaWindow.add(sample)
    this.deltaWindow = newDeltaWindow
    if not foundOutlier:
      # Calculate average elapsed time over the window
      var avg: float = 0.0
      for sample in this.deltaWindow:
        avg += sample / float(DELTA_WINDOW_CAP)
      # Convert into integer refresh rate
      this.refreshRate = max(1, int round(1.0 / avg))

