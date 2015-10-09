#!/bin/bash

#  Usage:
#     $ fetchPullRequest 110
#     gets PR#110 into a local branch called pr110

# Confirm that we are in a git repository
GIT_TOP=$(git rev-parse --show-toplevel)
RC=$?
if [ $RC != "0" ]; then
    exit $RC
fi

# Make sure there are no modified files (as a hard reset will happen)
NUM_MODIFIED_FILES=$(git diff --name-only | wc -l)
if [ $NUM_MODIFIED_FILES != "0" ]; then
    echo "Modified files detected. Aborting."
    exit 1
fi

# Get the branch name
if [ $# -eq 0 ]; then
    BRANCH_NAME=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ $? != "0" ]; then
        echo "Cannot determine branch. Aborting."
        exit 2
    fi

    # PR branches are named 'prNNN' where NNN is the PR number
    if [[ ! $BRANCH_NAME =~ ^pr[0-9]{1,}$ ]]; then
        echo "Branch $BRANCH_NAME is not a PR branch. Aborting."
        exit 3
    fi

    # Get the PR number from the branch name
    PR_NUM=${BRANCH_NAME:2}
elif [ $# -eq 1 ]; then
    PR_NUM=$1

    BRANCH_NAME=pr$PR_NUM
else
    echo "Too many arguments. Aborting."
    exit 4
fi

# Confirm that the PR exists
git ls-remote upstream | grep "pull/$PR_NUM/head" > /dev/null
RC=$?
if [ $RC != "0" ]; then
    echo "PR #$PR_NUM not found. Aborting."
    exit $RC
fi

git remote update -p

git checkout upstream/master

git fetch upstream pull/$PR_NUM/head
git checkout $BRANCH_NAME 2>/dev/null || git checkout -b $BRANCH_NAME
git reset --hard FETCH_HEAD

