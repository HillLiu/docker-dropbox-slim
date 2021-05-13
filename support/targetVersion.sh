#!/bin/bash
DIR="$( cd "$(dirname "$0")" ; pwd -P )"

if [ -z "$targetVersion" ]; then
targetVersion=$(awk -F "=" '/^targetVersion/ {print $2}' ${DIR}/../.env.build)
fi

echo $targetVersion
