#!/usr/bin/env bash

set -e

token=${1}

echo Testing beta versions
../entrypoint.sh $token modules/beta no_token dryrun | grep "\\-  version = \"1.12.0-beta1\""

echo Testing follow versions
../entrypoint.sh $token modules/follow no_token dryrun | grep "\\-  version = \"~> 1.0\""

echo Testing pinned versions
../entrypoint.sh $token modules/pinned no_token dryrun | grep "\\-  version = \"1.12.0\""
