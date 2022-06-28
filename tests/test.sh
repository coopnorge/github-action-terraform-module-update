#!/usr/bin/env bash

token=${1}
folder=${2:-modules/beta}


../entrypoint.sh $token $folder dryrun
