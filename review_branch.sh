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

# Confirm that we are in a git repository
GIT_TOP=$(git rev-parse --show-toplevel)
RC=$?
if [ $RC != "0" ]; then
    exit $RC
fi

# Get the branch name
if [ $# -eq 0 ]; then
    # Use the current branch if possible
    BRANCH_NAME=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ $? != "0" ]; then
        echo "Cannot determine branch to review. Aborting."
        exit 1
    fi
elif [ $# -eq 1 ]; then
    BRANCH_NAME=$1
    # TODO: validate given branch name
else
    echo "Too many arguments. Aborting."
    exit 1
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

COMMITS_LIST=(`git log --oneline $BASE..$BRANCH_NAME | cut -d" " -f1`)

echo "Found ${#COMMITS_LIST[@]} commits in branch $BRANCH_NAME"

for (( i=${#COMMITS_LIST[@]}-1, n=1; i>=0; --i, ++n ))
do
    COMMIT_SHORT_HASH=$(git log --format="%h" -n1 ${COMMITS_LIST[$i]})
    COMMIT_MSG_SUBJECT=$(git log --format="%s" -n1 ${COMMITS_LIST[$i]})
    COMMIT_MSG_BODY=$(git log --format="%b" -n1 ${COMMITS_LIST[$i]})

    # echo -e "    $n. \e[1m$COMMIT_HASH_AND_SUBJECT\e[0m"
    echo -e "    $n. (\e[34m$COMMIT_SHORT_HASH\e[0m) \e[1m$COMMIT_MSG_SUBJECT\e[0m"

    if [ -n "$COMMIT_MSG_BODY" ]; then
        # Split the commit message body into individual lines and print each
        # separately. This is needed so that we can indent each line of the
        # commit messsage body equally.
        mapfile -t COMMIT_MSG_BODY_LINES <<< "$COMMIT_MSG_BODY"

        for (( j=0; j<${#COMMIT_MSG_BODY_LINES[@]}; ++j ))
        do
            if [ -z "${COMMIT_MSG_BODY_LINES[$j]}" ]; then
                # There's no need to indent blank lines
                echo ""
            else
                echo "            ${COMMIT_MSG_BODY_LINES[$j]}"
            fi
        done
    fi

    echo -ne "                                            \e[35m... Press 'r' to review, 's' to skip\e[0m"

    # Silently read a single character
    read -s -n 1 C

    # Treat 'Enter' as 'r'
    if [ -z $C ]; then
        C='r'
    fi

    while [ $C != 'r' ] && [ $C != 'R' ] && [ $C != 's' ] && [ $C != 'S' ];
    do
        read -s -n 1 C

        if [ -z $C ]; then
            C='r'
        fi
    done

    if [ $C == 'r' ] || [ $C == 'R' ]; then
        $GD ${COMMITS_LIST[$i]}~1 ${COMMITS_LIST[$i]}
    fi

    # Remove the "Press 'r' to review..." line
    echo -e "\e[1A" # Go up one line
    echo -en "\e[0K" # Clear the line
done

