import os

switch("multimethods", "on")

var
  path = getEnv("PATH")
  libPath = joinPath(thisDir(), ".usr", "lib")
  endSep = getEnv("PATH")[^1] == PathSep

if not endSep:
  path &= PathSep
path &= libPath
if endSep:
  path &= PathSep

putEnv("PATH", path)

when defined(linux):
  let ldLibPath = getEnv("LD_LIBRARY_PATH")
  if ldLibPath.len > 0:
    putEnv("LD_LIBRARY_PATH", ldLibPath & PathSep & libPath)
    putEnv("LIBRARY_PATH", ldLibPath & PathSep & libPath)
  else:
    putEnv("LD_LIBRARY_PATH", libPath)
    putEnv("LIBRARY_PATH", libPath)

