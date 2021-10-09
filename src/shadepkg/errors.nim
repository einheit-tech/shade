import
  std/[
    macros,
    effecttraits,
    strformat
  ]

macro capture*(procThatMayError: typed): untyped =
  ## Coverts a proc that may raise an exception,
  ## into a tuple[value: type, ref Exception].
  if procThatMayError.kind != nnkCall:
    error("'capture' only works on procedure calls", procThatMayError)

  let
    impl = procThatMayError[0].getImpl
    raiseList = procThatMayError[0].getRaisesList()

  if raiseList.len == 0:
    let name = $impl[0]
    error(fmt"No raises in {name}.", procThatMayError)

  let returnType = impl.params[0]

  if returnType.kind == nnkEmpty:
    quote do:
      try:
        `procThatMayError`
        (ref Exception) nil
      except:
        getCurrentException()
  else:
    quote do:
      try:
        (value: `procThatMayError`, err: (ref Exception) nil)
      except:
        (value: default(typeof(`procThatMayError`)), err: getCurrentException())

template discardException*(body: typed) =
  try:
    body
  except:
    discard

