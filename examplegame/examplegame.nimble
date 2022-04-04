# Package
version = "0.1.0"
author = "Example Author"
description = "examplegame"
license = "?"
srcDir = "src"
bin = @["examplegame"]

# Dependencies
requires "nim >= 1.6.4"
requires "https://github.com/avahe-kellenberger/shade"

task runr, "Runs the game":
  exec "nim r -d:release src/examplegame.nim"

