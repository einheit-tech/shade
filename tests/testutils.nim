import
  macros,
  strformat

macro describe*(description: string, body: untyped): untyped =
  result = newStmtList()
  result.add quote do:
    echo `description`

  var testBlocks: seq[NimNode]
  for i, test in body:
    if test.kind == nnkCommand:
      let testDecl = test[0]
      if testDecl.kind == nnkDotExpr:
        if testDecl[0].kind == nnkIdent and testDecl[0].strVal == "test":
          if testDecl[1].kind == nnkIdent and testDecl[1].strVal == "only":
            test[0] = newIdentNode("test")
            testBlocks.add test

  if testBlocks.len > 0:
    result.add testBlocks
  else:
    result.add body

template test*(description: string, body: untyped) =
  block:
    # TODO: Print errors after {title} [Failed]
    try:
      body
      echo "  " & description & " [Success]"
    except:
      echo "  " & description & " [Failed]"
      echo "ERROR: " & getCurrentExceptionMsg()

template it*(description: string, body: untyped) = test(description, body)

template assertEquals*(a, b: untyped): untyped =
  if a != b:
    raise newException(Exception, "Expected " & (repr a) & " to equal " & (repr b))
    # raise newException(Exception, "nope")

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
      raiseAssert(astToStr(exception) &
                  " wasn't raised, another error was raised instead by:\n"&
                  astToStr(code))
  if wrong:
    raiseAssert(astToStr(exception) & " wasn't raised by:\n" & astToStr(code))

when isMainModule:
  describe "testing":
    test "test one":
      doAssert 1 == 1

    test.only "test two":
      doAssert 2 == 2

