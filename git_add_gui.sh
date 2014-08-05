#!/bin/bash

################################################################################
#
#   Description:
#   ------------
#   Script to graphically add modified files to the staging area. This is
#   helpful when one needs to add only some of the changes in the modified files
#   (and not all the changes). The usual way to do this is using:
#       $> git add -p
#   However doing this via the command line can be not only time consuming but
#   also sometimes error-prone. Using a graphical tool (personally I prefer
#   meld) makes the whole process a lot easier.
#
#   Usage:
#   ------
#       (first make sure that the script is executable)
#       $> /path/to/git_add_gui.sh [file1, file2, ...]
#   The graphical diff tool of your choice will be launched, with the modified
#   files on the left pane. Bring in the changes you want to stage to the right
#   pane, save and exit.
#
################################################################################

# Confirm that we are in a git repository
GIT_TOP=$(git rev-parse --show-toplevel)
RC=$?
if [ $RC != "0" ]; then
    exit $RC
fi

# Check if there are any modified files
NUM_MODIFIED_FILES=$(git diff --name-only | wc -l)
if [ $NUM_MODIFIED_FILES == "0" ]; then
    echo "There are no modified files. Aborting."
    exit 1
fi

# Get the list of files to work upon. All modified files if no files were
# explicitly given on the command line.
if [ $# -eq 0 ]; then
    FILES_LIST=(`git diff --name-only`)
else
    FILES_LIST=("$@")
fi

# Get a diff tool to be used
# First check if a diff tool has been configured in git config, if not get it
# manually.
DIFF_TOOL=$(git config diff.tool)

if [ -z $DIFF_TOOL ]; then
    echo -n "No diff tool specified in git config, enter tool to use: "
    read DIFF_TOOL
fi

while [ -z $DIFF_TOOL ];
do
    echo -n "No diff tool specified, enter tool to use: "
    read DIFF_TOOL
done

# Check if the diff tool exists
type $DIFF_TOOL &>/dev/null
if [ $? != "0" ]; then
    echo "$DIFF_TOOL: no such diff tool exists, aborting."
    exit 1
fi

# Create a temporary directory
TMPDIR=$(mktemp -d)

# For each file in the files list
for (( i=0; i<${#FILES_LIST[@]}; ++i ))
do
    FILE=$GIT_TOP/${FILES_LIST[$i]}

    cp $FILE $TMPDIR

    FILENAME=$(basename $FILE)

    # This has your changes in it
    WORK_TREE_VERSION=$TMPDIR/$FILENAME

    # This has the pristine version
    TEMP_FILE=$(git checkout-index --temp $FILE | cut -f1)
    INDEX_VERSION=$GIT_TOP/$TEMP_FILE

    # Launch the difftool to compare the work tree version and the index version
    # Bring in whatever changes are to be staged into the index version
    # Save the index version and quit when done
    $DIFF_TOOL $WORK_TREE_VERSION $INDEX_VERSION

    # Swap files around to run git add
    mv $FILE $WORK_TREE_VERSION
    mv $INDEX_VERSION $FILE
    git add $FILE
    mv $WORK_TREE_VERSION $FILE

    # Instead of swapping this way, we could also calculate the diff and apply
    # it directly to the index as follows, but I haven't tested this.
    # git diff --no-index -- $FILE $INDEX_VERSION | git apply --cached
done

# Remove the temporary directory
rm -rf $TMPDIR

