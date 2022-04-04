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

echo "defined(linux) ? ", $defined(linux)

when defined(linux):
  putEnv("LD_LIBRARY_PATH", getEnv("LD_LIBRARY_PATH") & PathSep & libPath)
  echo "set up LD_LIBRARY_PATH: " & getEnv("LD_LIBRARY_PATH")

