#!/bin/bash

################################################################################
#
#   Description:
#   ------------
#   TODO
#
#   Usage:
#   ------
#       (first make sure that the script is executable)
#       $> /path/to/list_files.sh commit1 commit2
#
################################################################################

# Confirm minimum number of arguments
if [ $# -lt 1 ]; then
    echo "Need at least one commit to list the files from."
    exit 1
fi

# Confirm that we are in a git repository
GIT_TOP=$(git rev-parse --show-toplevel)
RC=$?
if [ $RC != "0" ]; then
    exit $RC
fi

for COMMIT in "$@"
do
    git rev-parse --quiet --verify $COMMIT > /dev/null
    if [ $? != "0" ]; then
        echo "$COMMIT is not a valid git object"
        echo ""
        continue
    fi

    FILES_LIST=(`git diff-tree --no-commit-id --name-only -r $COMMIT`)

    echo "Commit $COMMIT modifies the following ${#FILES_LIST[@]} files:"
    for (( i=0; i<${#FILES_LIST[@]}; ++i ))
    do
        echo "    ${FILES_LIST[$i]}"
    done

    echo ""
done

exit 0

