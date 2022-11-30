#!/bin/bash -e

while getopts "a:t:p:f:" opt; do
  case $opt in
  a)
    artifactsLocation=$OPTARG #base uri of the file including the container
    ;;
  t)
    token=$OPTARG #saToken for the uri - use "?" if the artifact is not secured via sasToken
    ;;
  p)
    pathToFile=$OPTARG #path to the file relative to artifactsLocation
    ;;
  f)
    fileToInstall=$OPTARG #filename of the file to download from storage
    ;;
  *)
    >&2 echo "Error: no opts"
    exit 1
  esac
done

fileUrl="$artifactsLocation$pathToFile/$fileToInstall$token"

stagingDir="/staging"
mkdir -p "$stagingDir"
echo "...................."
echo "path: $stagingDir/$fileToInstall"
echo "...................."
echo "uri: $fileUrl"
echo "...................."

curl -v -o "$stagingDir/$fileToInstall" "$fileUrl"
cat "$stagingDir/$fileToInstall"

chmod +x "$stagingDir/$fileToInstall"
"$stagingDir/$fileToInstall"