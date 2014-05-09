#!/bin/bash

# Confirm that we are in a git repository
GIT_TOP=$(git rev-parse --show-toplevel)
RC=$?
if [ $RC != "0" ]; then
    exit $RC
fi

# Check if a diff tool has been configured in git config
DIFF_TOOL=$(git config diff.tool)

# Get a diff tool to be used
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

# For each modified file
git diff --name-only | while read FILE;
do
    FILE=$GIT_TOP/$FILE

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

    # swap files around to run git add
    mv $FILE $WORK_TREE_VERSION
    mv $INDEX_VERSION $FILE
    git add $FILE
    mv $WORK_TREE_VERSION $FILE

    # Instead of swapping this way, we could also calculate the diff and apply
    # it directly to the index as follows, but I haven't tested this.
    # git diff --no-index -- $FILE $INDEX_VERSION | git apply --cached
done

rm -rf $TMPDIR

