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

COMMIT=$1

git rev-parse --quiet --verify $COMMIT > /dev/null
if [ $? != "0" ]; then
    echo "$COMMIT is not a valid git object"
    exit 1
fi

COMMAND=$2

FILES_LIST=(`git diff-tree --no-commit-id --name-only -r $COMMIT`)

echo "Commit $COMMIT modifies ${#FILES_LIST[@]} files:"
for (( i=0; i<${#FILES_LIST[@]}; ++i ))
do
    FILE_NAME=${FILES_LIST[$i]}
    if [ -z "$COMMAND" ]; then
        echo "    $FILE_NAME"
    elif [ "$COMMAND" = "--file-patches" ]; then
        # PATCH_FILE_NAME="$i"_"$COMMIT"_"$FILE_NAME"
        # ORIG_PATCH_FILE=$(git format-patch -1 $COMMIT $FILE_NAME)
        # mv $ORIG_PATCH_FILE $PATCH_FILE_NAME
        echo "git format-patch -1 $COMMIT $FILE_NAME"
    fi
done

exit 0

