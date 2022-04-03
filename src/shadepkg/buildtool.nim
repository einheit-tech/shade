import
  std/httpclient,
  zippy/tarballs_v1,
  parseopt,
  strformat,
  strutils,
  os,
  re

const usrLibDir = ".usr/lib"

proc printHelp() =
  echo fmt"""
    Options:
      --help
        Prints this help message

      --compress
        Compresses the contents of "{usrLibDir}"

      --fetch
        Fetches and extracts an archive to "{usrLibDir}"
  """.dedent()

proc cleanup() =
  let startingDir = getCurrentDir()
  setCurrentDir(usrLibDir)

  # Delete symlinks
  for (pathComponentKind, path) in walkDir("."):
    if pathComponentKind == pcLinkToFile:
      removeFile path

  for (pathComponentKind, path) in walkDir("."):
    if pathComponentKind == pcFile and path =~ re"\.\/(.*)\-.*\.so.*":
      moveFile(path, fmt"{matches[0]}.so")

  setCurrentDir(startingDir)

proc compress() =
  cleanup()
  createTarball(usrLibDir, "deps_artifact.tar.gz")

proc fetch() =
  # let client = newHttpClient()
  # client.downloadFile("", "deps.tar.gz")
  echo "TODO: fetch"

var optParser = initOptParser()
let remainingArgs = optParser.remainingArgs()
# Only supporting one option at a time, currently.
if remainingArgs.len != 1:
  printHelp()
  quit()

let command = remainingArgs[0]
case command:
  of "--compress":
    compress()
  of "--fetch":
    fetch()
  else:
    printHelp()

