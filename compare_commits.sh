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
#       $> /path/to/compare_commits.sh commit1 commit2
#
################################################################################

# Confirm minimum number of arguments
if [ $# -lt 2 ]; then
    echo "Need two commits to compare"
    exit 1
fi

# Confirm that we are in a git repository
GIT_TOP=$(git rev-parse --show-toplevel)
RC=$?
if [ $RC != "0" ]; then
    exit $RC
fi

COMMIT1=$1
COMMIT2=$2

#TODO: Confirm that the commits are valid

COMMIT1_FILES=(`git diff-tree --no-commit-id --name-only -r $COMMIT1`)
COMMIT2_FILES=(`git diff-tree --no-commit-id --name-only -r $COMMIT2`)

if [ ${#COMMIT1_FILES[@]} -ne ${#COMMIT2_FILES[@]} ]; then
    echo "Mismatch in the number of files, so obviously the commits differ."

    echo -n "Show the list of modified files for both commits? (y/n): "
    read YES_OR_NO
    if [ $YES_OR_NO == "y" ] || [ $YES_OR_NO == "Y" ]; then
        echo "Commit $COMMIT1 modifies the following ${#COMMIT1_FILES[@]} files:"
        for (( i=0; i<${#COMMIT1_FILES[@]}; ++i ))
        do
            echo "    ${COMMIT1_FILES[$i]}"
        done
        echo ""
        echo "Commit $COMMIT2 modifies the following ${#COMMIT2_FILES[@]} files:"
        for (( i=0; i<${#COMMIT2_FILES[@]}; ++i ))
        do
            echo "    ${COMMIT2_FILES[$i]}"
        done
    fi

    exit 2
fi

for (( i=0; i<${#COMMIT1_FILES[@]}; ++i ))
do
    #TODO: is there a better way to do this instead of such redirection to
    #      temporary files?
    git show $COMMIT1:${COMMIT1_FILES[$i]} > /tmp/file1
    git show $COMMIT2:${COMMIT1_FILES[$i]} > /tmp/file2

    cmp --quiet /tmp/file1 /tmp/file2
    if [ $? != "0" ]; then
        DIFFERING_FILES=("${DIFFERING_FILES[@]}" "${COMMIT1_FILES[$i]}")
    fi
done

if [ ${#DIFFERING_FILES[@]} -eq 0 ]; then
    echo "The commits are identical."
else
    echo "There are ${#DIFFERING_FILES[@]} different files in the two commits:"

    for (( i=0; i<${#DIFFERING_FILES[@]}; ++i ))
    do
        echo "    * ${DIFFERING_FILES[$i]}"
    done

    echo ""
    echo "This might help to locate the problem:"
    echo "    F=<file>; git difftool --no-prompt $COMMIT1:\$F $COMMIT2:\$F"
fi

exit 0

