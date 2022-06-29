#!/usr/bin/env bash


token=${1}

test_tf_update_action() {
  ../entrypoint.sh $token ${1} no_token dryrun | grep "${2}"
  status=$?
  echo $status
  if [[ ! ${status} -eq 0 ]] ; then
    echo Failed. Expected to find ${2}
    exit 1
  fi
}

test_tf_update_action modules/beta "\\-  version = \"1.12.0-beta1\""
exit


echo Testing beta versions
../entrypoint.sh $token modules/beta no_token dryrun | grep "\\-  version = \"1.12.0-beta1\"" || (echo Failed. Should return: \'-  version = \"1.12.0-beta1\"\' ; exit 1)

echo Testing follow versions
../entrypoint.sh $token modules/follow no_token dryrun | grep "\\-  version = \"~> 1.0\"" || (echo Failed. Should return: \'-  version = \"1.12.0-beta1\"\' ; exit 1)

echo Testing pinned versions
../entrypoint.sh $token modules/pinned no_token dryrun | grep "\\-  version = \"1.12.0\"" || (echo Failed. Should return: \'-  version = \"1.12.0-beta1\"\' ; exit 1)
