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
echo "set up PATH: " & getEnv("PATH")

echo "defined(linux) ? ", $defined(linux)

when defined(linux):
  let ldLibPath = getEnv("LD_LIBRARY_PATH")
  if ldLibPath.len > 0:
    putEnv("LD_LIBRARY_PATH", ldLibPath & PathSep & libPath)
  else:
    putEnv("LD_LIBRARY_PATH", libPath)

  echo "set up LD_LIBRARY_PATH: " & getEnv("LD_LIBRARY_PATH")

