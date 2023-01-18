#!/bin/bash -e

while getopts "a:t:p:f:l:" opt; do
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

wget "https://aka.ms/downloadazcopy-v10-linux" -O "$stagingDir"/azcopy.tar.gz
tar -xvf "$stagingDir/azcopy.tar.gz" -C "$stagingDir" --strip=1
"$stagingDir"/azcopy copy "$artifactsLocation$pathToFile$token" "$stagingDir" --recursive=true

chmod +x "$stagingDir/scripts/$fileToInstall"
#bash -c "$stagingDir/scripts/$fileToInstall"