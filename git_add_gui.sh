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
    FILE_FULL_PATH=$(readlink -m ${FILES_LIST[$i]})

    cp --preserve=all $FILE_FULL_PATH $TMPDIR

    FILENAME=$(basename $FILE_FULL_PATH)

    # This has your changes in it
    WORK_TREE_VERSION=$TMPDIR/$FILENAME

    # The following command will create a file called '.merge_file_xxxxxx'
    # containing the pristine version before any modifications. This file will
    # be created in the top git directory (even if the command is run from deep
    # inside the git hierarchy). The 'xxxxxx' part in the file name is a random
    # string of alphanumeric characters.
    TEMP_FILE=$(git checkout-index --temp $FILE_FULL_PATH | cut -f1)
    INDEX_VERSION=$GIT_TOP/$TEMP_FILE

    # Launch the difftool to compare the work tree version and the index version
    # Bring in whatever changes are to be staged into the index version
    # Save the index version and quit when done
    $DIFF_TOOL $WORK_TREE_VERSION $INDEX_VERSION

    # Temporarily save the file containing all modified changes
    mv $FILE_FULL_PATH $WORK_TREE_VERSION

    # Put the file containing only the changes to be staged into its rightful
    # location, so that we can run 'git add' on it
    mv $INDEX_VERSION $FILE_FULL_PATH
    git add $FILE_FULL_PATH

    # Restore the temporarily saved file, so that the unstaged changes are not
    # lost
    mv $WORK_TREE_VERSION $FILE_FULL_PATH

    # Instead of swapping files in the above few commands, we could also
    # calculate the diff and apply it directly to the index as follows, but I
    # haven't tested this.
    # git diff --no-index -- $FILE $INDEX_VERSION | git apply --cached
done

# Remove the temporary directory
rm -rf $TMPDIR
