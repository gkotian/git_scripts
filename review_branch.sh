#!/bin/bash

# TODO: provide help text

# TODO: use getopt to parse input arguments

# TODO: confirm valid branch

# TODO: take a base as optional second argument
#       if nothing is given, assume base as upstream/master

# Confirm minimum number of arguments
if [ $# -lt 1 ]; then
    echo "No branch given"
    exit 1
fi

# Confirm that we are in a git repository
GIT_TOP=$(git rev-parse --show-toplevel)
RC=$?
if [ $RC != "0" ]; then
    exit $RC
fi

# If a diff tool has been configured, then use that; otherwise just do a simple
# git diff.
DIFF_TOOL=$(git config diff.tool)

if [ -z $DIFF_TOOL ]; then
    GD="git diff"
else
    # Check if the diff tool exists
    type $DIFF_TOOL &>/dev/null
    if [ $? != "0" ]; then
        echo "$DIFF_TOOL: no such diff tool exists."
        GD="git diff"
    else
        GD="git difftool --no-prompt"
    fi
fi

BASE="upstream/master"

COMMITS_LIST=(`git log --oneline $BASE..$1 | cut -d" " -f1`)

echo "Found ${#COMMITS_LIST[@]} commits in branch $1"

for (( i=${#COMMITS_LIST[@]}-1, n=1; i>=0; --i, ++n ))
do
    echo -n "    Press enter to diff commit $n (${COMMITS_LIST[$i]})"
    read dummy
    $GD ${COMMITS_LIST[$i]}~1 ${COMMITS_LIST[$i]}
done

