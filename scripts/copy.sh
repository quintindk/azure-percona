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

stagingDir="/staging"
mkdir -p "$stagingDir"

getFile "https://aka.ms/downloadazcopy-v10-linux" "$stagingDir/azcopy.tar.gz"
tar -xvf "$stagingDir/azcopy.tar.gz" -C $stagingDir
azcopy copy $stagingDir "$artifactsLocation$pathToFile$token" --recursive=true

chmod +x "$stagingDir/$fileToInstall"
bash -c "$stagingDir/$fileToInstall"