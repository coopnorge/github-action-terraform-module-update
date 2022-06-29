#!/usr/bin/env bash

token=${1}
folder=${2:-modules/beta}


echo Testing beta versions
../entrypoint.sh $token modules/beta no_token dryrun #| grep "-  version = \"1.12.0-beta1\""
