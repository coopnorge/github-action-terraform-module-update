#!/usr/bin/env bash


token=${1}

test_tf_update_action() {
  DEBUG=enabeld ../entrypoint.sh $token ${1} no_token dryrun | grep "${2}"
  status=$?
  if [[ ! ${status} -eq 0 ]] ; then
    echo Failed. Testing ${1}
    echo Expected to find ${2}
    exit 1
  fi
}

test_tf_update_action modules/beta "\\-  version = \"1.12.0-beta1\""

test_tf_update_action modules/follow "\\-  version = \"~> 1.0\""

test_tf_update_action modules/pinned "\\-  version = \"1.12.0\""