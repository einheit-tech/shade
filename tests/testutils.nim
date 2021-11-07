import
  macros,
  strformat,
  terminal

template echoSuccess(args: varargs[untyped]) =
  styledWriteLine(
    stdout,
    fgGreen,
    "  [Success]: ",
    fgDefault,
    args
  )

template echoError(args: varargs[untyped]) =
  styledWriteLine(
    stdout,
    fgRed,
    "  [Failed]: ",
    fgDefault,
    args
  )

macro describe*(description: string, body: untyped): untyped =
  result = newStmtList()
  result.add quote do:
    styledWrite(
      stdout,
      fgYellow,
      styleUnderscore,
      `description`
    )
    styledWriteLine(
      stdout,
      fgYellow,
      ":"
    )

  var testBlocks: seq[NimNode]
  for test in body:
    if test.kind == nnkCommand:
      let testDecl = test[0]
      if testDecl.kind == nnkDotExpr:
        if testDecl[0].kind == nnkIdent:
          if testDecl[0].strVal == "test" or testDecl[0].strVal == "it":
            if testDecl[1].kind == nnkIdent and testDecl[1].strVal == "only":
              test[0] = newIdentNode("test")
              testBlocks.add test

  if testBlocks.len > 0:
    result.add testBlocks
  else:
    result.add body

template test*(description: string, body: untyped) =
  try:
    body
    echoSuccess(description)
  except:
    echoError(description, "\n\t", getCurrentExceptionMsg())

template it*(description: string, body: untyped) =
  test(description, body)

template assertEquals*(a, b: untyped): untyped =
  if a != b:
    raise newException(
      Exception,
      "Expected " & (repr a) & " to equal " & (repr b) &
      "\n\tassertEquals(" & astToStr(a) & ", " & astToStr(b) & ")"
    )

template assertAlmostEquals*(a, b: float): untyped =
  if not almostEquals(a, b):
    raise newException(
      Exception,
      "Expected " & (repr a) & " to equal " & (repr b) &
      "\n\tassertAlmostEquals(" & astToStr(a) & ", " & astToStr(b) & ")"
    )

template assertRaises*(exception: typedesc, errorMessage: string, code: untyped) =
  ## Raises ``AssertionDefect`` if specified ``code`` does not raise the
  ## specified exception. Example:
  ##
  ## .. code-block:: nim
  ##  doAssertRaisesSpecific(ValueError, "wrong value!"):
  ##    raise newException(ValueError, "Hello World")
  var wrong = false
  when Exception is exception:
    try:
      if true:
        code
      wrong = true
    except Exception as e:
      if e.msg != errorMessage:
        raiseAssert("Wrong exception was raised: " & e.msg)
      discard
  else:
    try:
      if true:
        code
      wrong = true
    except exception:
      discard
    except Exception:
      raiseAssert(
        astToStr(exception) &
        " wasn't raised, another error was raised instead by:\n"&
        astToStr(code)
      )

  if wrong:
    raiseAssert(astToStr(exception) & " wasn't raised by:\n" & astToStr(code))

when isMainModule:
  describe "testing":
    test "test one":
      doAssert 1 == 1

    test.only "test two":
      doAssert 2 == 2

