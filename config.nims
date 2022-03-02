import os

switch("threads", "on")
switch("multimethods", "on")

var path = getEnv("PATH")
var endSep = getEnv("PATH")[^1] == PathSep

if not endSep:
  path &= PathSep
path &= joinPath(".usr", "lib")
if endSep:
  path &= PathSep

putEnv("PATH", path)
