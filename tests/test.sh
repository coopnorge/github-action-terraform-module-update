#!/usr/bin/env bash

token=${1}
folder=${2:="tests/modules/beta"}


../entrypoint.sh $token $folder dryrun
