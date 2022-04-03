import
  std/httpclient,
  zippy/[tarballs, tarballs_v1],
  parseopt,
  strformat,
  strutils,
  os,
  re

const
  usrDir = ".usr"
  usrLibDir = fmt"{usrDir}/lib"
  artifactFilename = "deps_artifact.tar.gz"
  artifactDownloadLink = fmt"https://github.com/avahe-kellenberger/shade/raw/build-tool/{artifactFilename}"

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

template withDir(dir: string, body: untyped) =
  let startingDir = getCurrentDir()
  setCurrentDir(usrLibDir)
  body
  setCurrentDir(startingDir)

proc cleanup() =
  withDir(usrLibDir):
    # Delete symlinks
    for (pathComponentKind, path) in walkDir("."):
      if pathComponentKind == pcLinkToFile:
        removeFile path

    # Rename files to be the proper foo.so names
    for (pathComponentKind, path) in walkDir("."):
      if pathComponentKind == pcFile and path =~ re"\.\/(.*)\-.*\.so.*":
        moveFile(path, fmt"{matches[0]}.so")

proc compress() =
  cleanup()
  createTarball(usrLibDir, artifactFilename)

proc fetch() =
  let client = newHttpClient()
  client.downloadFile(artifactDownloadLink, artifactFilename)
  # NOTE: extractAll requires the destination to NOT exist.
  removeDir(usrLibDir)
  extractAll(artifactFilename, usrDir)

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

