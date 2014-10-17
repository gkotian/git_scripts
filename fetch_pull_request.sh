#!/bin/bash

#  Usage:
#     $ fetchPullRequest 110
#     gets PR#110 into a local branch called pr110

# Make sure there are no modified files (as a hard reset will happen)
NUM_MODIFIED_FILES=$(git diff --name-only | wc -l)
if [ $NUM_MODIFIED_FILES != "0" ]; then
    echo "Modified files detected. Aborting."
    exit 1
fi

# TODO: confirm PR exists

git remote update

git checkout upstream/master

git fetch upstream pull/$1/head
git checkout pr$1 2>/dev/null || git checkout -b pr$1
git reset --hard FETCH_HEAD

