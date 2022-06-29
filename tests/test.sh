#!/usr/bin/env bash

token=${1}

set -e

echo Testing beta versions
../entrypoint.sh $token modules/beta no_token dryrun | grep "\\-  version = \"1.12.0-beta1\""

echo Testing follow versions
../entrypoint.sh $token modules/follow no_token dryrun | grep "\\-  version = \"~> 1.0\""

echo Testing pinned versions
../entrypoint.sh $token modules/pinned no_token dryrun | grep "\\-  version = \"1.12.0\""
