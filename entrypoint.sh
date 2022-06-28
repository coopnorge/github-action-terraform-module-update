#!/usr/bin/env bash

TFE_TOKEN=$1
TERRADIR=$2
GITHUB_TOKEN=$3
DRY_RUN_PR=${4:-no}
REGISTRY_API_PATH="api/registry/v1/modules"


print_usage() {
  echo 
  echo usage: ./$0 terraform_token terraform_manifests_directory github_token dryrun
  echo
  echo terraform_token = Token which allows requests to fetch registry info
  echo terraform_manifests_directory = Directory where the terraform files are
  echo github_token = token which allows creating pull requests
  echo dryrun = dryrun the push of the branch and the pr, set to dryrun to enable dryrun

}

debug() {
  if [[ "${DEBUG}" == "enabled" ]] ; then
    >&2 echo DEBUG: "$@"
  fi
}

DEBUG=enabled
if [ -z $TFE_TOKEN ] ; then print_usage ; exit 1 ; fi
if [ -z $TERRADIR ] ; then print_usage ; exit 1 ; fi
if [ -z $GITHUB_TOKEN ] ; then print_usage ; exit 1 ; fi
if [ ! -d $TERRADIR ]; then echo supplied directory is not a directory ; exit 1 ; fi

export GITHUB_TOKEN

get_latest_version() {
  debug "$1/$REGISTRY_API_PATH/$2"
  curl --fail -s -H "Authorization: Bearer $TFE_TOKEN" \
    https://$1/$REGISTRY_API_PATH/$2 | jq -r ".versions[-1]"
}

get_registry_dns() {
  echo $1 | cut -d / -f 1
}

get_module_name() {
  echo $1 | cut -d / -f2-
}

create_pull_request() {
  branch=$(echo $1-$2 | sed 's/\//-/g')
  if git status --porcelain  | grep -q M ; then
    git checkout -b $branch
    git commit -am 'updating $1 to $2'
    if [[ "${DRYRUN}"  == "dryrun" ]] ; then
      git diff | cat -
    else
      git push --set-upstream origin $branch
      gh pr create \
        --base main \
        --title "Updating terraform module $1 to version $2" \
        --body "Updating terraform module $1 to version $2. This PR is created by a script"
    fi
    git checkout main
    git branch -D $branch
  else
    echo No changes, nothing to commit
  fi
}

declare -a modules=()
debug terradir is ${TERRADIR}
pushd "${TERRADIR}"
for file in *.tf ; do
  for module in $(hcl2json $file | yq e ".module.*[].source" | sort | uniq) ; do
    if [[ ! " ${modules[*]} " =~ " ${module} " ]]; then
        modules+=(${module})
        debug Found module: $module
        registry=$(get_registry_dns $module)
        debug Found registry: $registry
        module_name=$(get_module_name $module)
        debug Found module_name: $module_name
        version=$(get_latest_version $registry $module_name)
        debug Found
        tfupdate module $module ./ -v $version
        create_pull_request $module_name $version
    fi
  done
done
popd