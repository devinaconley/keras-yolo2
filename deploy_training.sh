#!/bin/bash
# custom yolo2
# Deployment script for packaging and pushing dlaas training job

# localize
cd "$(dirname "$0")"
projectDir=$(pwd)

# constants
pathManifest="$projectDir"/etc/manifest/training-definition.yml
pathStagingDir="$projectDir"/stage

# get args
while [ ! $# -eq 0 ]
do
    case "$1" in
        --wheels | -w)
            buildWheels=true
            break;;
        --apt | -f)
            aptDownload=true
            break;;
    esac
    shift
done

# setup
if [ -d "$pathStagingDir" ]
then
    rm -r "$pathStagingDir"
fi
mkdir -p "$pathStagingDir"/stage

# stage code
cp {train.py,utils.py,preprocessing.py,predict.py,gen_anchors.py,frontend.py,backend.py,config.json} "$pathStagingDir"/stage/
cp etc/dlaas_additional_requirements.txt "$pathStagingDir"/stage/requirements.txt

# stage training definition zipfile
cd "$pathStagingDir"/stage
zip -r "$pathStagingDir"/package.zip .

if [ "$buildWheels" = true ]
then
    # build wheels for additional requirements by mounting to dlaas base image
    cd "$pathStagingDir"
    docker run --rm -v "$PWD:/tmp" tensorflow/tensorflow:1.7.0-gpu-py3 \
           bash  -c "cd /tmp && pip wheel --wheel-dir=wheels -r stage/requirements.txt"

    # stage dependencies zipfile
    cd "$pathStagingDir"
    zip -r "$pathStagingDir"/wheels.zip wheels
fi

# deploy as training definition
cd "$projectDir"
unzip -l "$pathStagingDir"/package.zip
bx ml store training-definitions "$pathStagingDir"/package.zip "$pathManifest"

# instruct user to upload dependencies file
echo "Upload archive: $pathStagingDir/wheels.zip to COS training data bucket"