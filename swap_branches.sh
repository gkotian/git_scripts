#!/bin/bash

################################################################################
#
#   Description:
#   ------------
#   TODO
#
#   Usage:
#   ------
#   TODO
#
################################################################################

# Confirm that we are in a git repository
GIT_TOP=$(git rev-parse --show-toplevel)
RC=$?
if [ $RC != "0" ]; then
    exit $RC
fi

# Confirm the right number of command line arguments
if [ $# != "2" ]; then
    echo "Incorrect number of arguments. Aborting."
    exit 1
fi

# Make sure there are no modified files (just erring on the side of caution)
NUM_MODIFIED_FILES=$(git diff --name-only | wc -l)
if [ $NUM_MODIFIED_FILES -ne 0 ]; then
    echo "Modified files detected. Aborting."
    exit 2
fi

BRANCH1=$1
BRANCH2=$2

# Get the commit hashes of both branches (which conveniently confirms that both
# branches exist)
COMMIT_HASH1=$(git show-ref --heads -s $BRANCH1)
if [ -z "$COMMIT_HASH1" ]; then
    echo "Branch '$BRANCH1' not found. Aborting."
    exit 3
fi

COMMIT_HASH2=$(git show-ref --heads -s $BRANCH2)
if [ -z "$COMMIT_HASH2" ]; then
    echo "Branch '$BRANCH2' not found. Aborting."
    exit 3
fi

git co -B $BRANCH1 $COMMIT_HASH2 >/dev/null 2>&1
git co -B $BRANCH2 $COMMIT_HASH1 >/dev/null 2>&1

echo "Swapped branches '$BRANCH1' & '$BRANCH2'"

