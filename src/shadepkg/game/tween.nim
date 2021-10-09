import task
export task

type Tween* = ref object of Task
  duration: float
  interpolate: proc(deltaTime: float)

proc initTween*(
  tween: Tween,
  duration: float,
  interpolate: proc(deltaTime: float),
  onCompletion: proc(this: Tween)
) =
  initTask(
    tween,
    interpolate,
    proc(this: Tween): bool = tween.elapsedTime >= tween.duration,
    onCompletion
  )
  tween.duration = duration

proc newTween*(
  duration: float,
  interpolate: proc(deltaTime: float),
  onCompletion: proc(this: Tween)
): Tween =
  result = Tween()
  initTween(result, duration, interpolate, onCompletion)

when isMainModule:
  var i = 0
  let tween: Tween = newTween(
    2.5,
    (proc(deltaTime: float) = echo $i; i.inc),
    proc() = echo "done!"
  )

  while not tween.completed:
    tween.update(0.5)

