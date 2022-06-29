#!/usr/bin/env bash


token=${1}

test_tf_update_action() {
  echo Testing ${1}, expecting ${2}
  interest=$(../entrypoint.sh $token ${1} no_token dryrun | grep -A 2 helloworld_github )
  if ! echo $interest | grep -q "${2}" ; then
    echo Failed!
    echo Found:
    echo $interest
    exit 1
  else
    echo Success
  fi
}

test_tf_update_action modules/beta "1.12.0-beta1"

test_tf_update_action modules/follow "~> 1.0"

test_tf_update_action modules/pinned "1.12.0"