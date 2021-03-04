#!/bin/bash

set -o pipefail
set -e
set -u
#set -x

function usage()
{
  echo "Usage:"
  echo "  -h help"
  echo "  -p project"
  exit 0
}
##########
# Functions
##########
function current_pr_status
{
  echo  "PR: $(gh pr status | grep -A1 $source_branch | tail -n2)"
}

function should_open_pr
{
  [[ -z $(gh pr list --state 'open' --base "$target_branch"| grep -A1 "$source_branch") ]]
}

function create_pr
{
  gh pr create --base "$target_branch" --head "$source_branch" -t "test release $version" --body "test release $version"
  git push -q
  sleep 10
}

function wait_pr_mergeable
{
until gh pr checks "$source_branch"; do sleep 5; done
current_pr_status

#until gh pr status | grep -A2 "Current branch" | tail -n1 | grep -q "Checks passing"; do sleep 1; done
#echo "PR $(gh pr status | grep -A2 'Current branch' | tail -n1 | awk -F- '{print $2}')"
until gh pr status | grep -A1 "$source_branch" | tail -n1 | grep -q "Approved"; do
  current_pr_status
  sleep 5;
done
}

function run_updates
{
  git checkout "$source_branch"
  git pull
  npm run latest:${target_branch} --if-present
  if [ -n "$(git status --porcelain -u no)" ]; then
    echo commiting changes
    git commit -a -m "Bumping linkurious dependencies to ${target_branch}"
  fi
}

##########
# Main
##########
debug=""
version=""
project=""
source_branch="develop"
target_branch="master"
continuation_token=""
continuation_token_qs=""
token_increment=0
should_run_updates=false
while getopts "p:o:s:t:v:hdu" argument
do
  case $argument in
    p) project=$OPTARG;;
    d) debug='-d';;
    s) source_branch=$OPTARG;;
    t) target_branch=$OPTARG;;
    v) version=$OPTARG;;
    u) should_run_updates=true;;
    h) usage;;
  esac
done

if [[ -z $version ]]; then
  echo "Missing version"
  usage
fi

if [[ -z $project ]]; then
  echo "Missing project"
  usage
fi


if should_open_pr ; then
  echo "Should open PR"
  if [ should_run_updates ]; then
    run_updates
  fi
  create_pr
fi

wait_pr_mergeable
