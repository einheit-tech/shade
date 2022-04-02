import
  std/httpclient,
  zippy/tarballs_v1,
  parseopt,
  strformat,
  strutils

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

proc compress() =
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

