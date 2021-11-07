import
  os,
  osproc,
  parseopt,
  strutils,
  strformat,
  locks

var
  cmdlineArgs = "--hints: off "
  lock: Lock
  globalExitCode = 0

proc testFile(a: tuple[file: string, args: string]) {.thread.} =
  let (output, exitcode) = execCmdEx(
    command = fmt"nim {a.args} r {a.file}"
  )

  acquire(lock)
  echo output
  if exitcode != 0 or output.contains("[Failed]: "):
    globalExitCode = 1
  release(lock)

when isMainModule:
  cmdlineArgs.add initOptParser().cmdLineRest() & " "
  
  var testFiles: seq[string]
  for file in walkDirRec("./shade"):
    if file.endsWith(".nim"):
      testFiles.add(file)

  if testFiles.len > 1:
    initLock(lock)

    var threads = newSeq[Thread[tuple[file: string, args: string]]](testFiles.len)
    for i in 0..testFiles.high:
      createThread(threads[i], testFile, (testFiles[i], cmdlineArgs))
    joinThreads(threads)
    
    deinitLock(lock)

  elif testFiles.len == 1:
    testFile((testFiles[0], cmdlineArgs))
  else:
    echo "No tests found."


  quit globalExitCode

