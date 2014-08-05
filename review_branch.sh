#!/bin/bash

################################################################################
#
#   Description:
#   ------------
#   Script to review a git branch by comparing the changes made in each commit
#   of the branch, starting with the oldest commit. The base (commit from which
#   the branch under review has been created) is assumed to be
#   'upstream/master'.
#
#   Usage:
#   ------
#       (first make sure that the script is executable)
#       $> /path/to/review_branch.sh branch_name
#   If a graphical diff tool has been configured in gitconfig, then that will be
#   launched (for each file changed in each commit), or else simple 'git diff'
#   will be done as a fallback.
#   The user will have to give manual confirmation before beginning the diff of
#   a new commit, for clear distinction between changes made in separate
#   commits.
#
################################################################################

DEFAULT_BASE="upstream/master"

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

BASE=$DEFAULT_BASE

COMMITS_LIST=(`git log --oneline $BASE..$1 | cut -d" " -f1`)

echo "Found ${#COMMITS_LIST[@]} commits in branch $1"

for (( i=${#COMMITS_LIST[@]}-1, n=1; i>=0; --i, ++n ))
do
    echo -n "    Press enter to diff commit $n (${COMMITS_LIST[$i]})"
    read dummy
    $GD ${COMMITS_LIST[$i]}~1 ${COMMITS_LIST[$i]}
done

