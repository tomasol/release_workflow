#!/bin/bash

function tag_message {
    echo "TBO Services release $RELEASE_VERSION."
}

function bump_to_future_hotfix_message {
    echo "Bump version to ${FUTURE_HOTFIX_VERSION}"
}

function create_release_message {
    echo "Create release $RELEASE_VERSION"
}

function bump_to_future_develop_message {
    echo "Bump version to ${FUTURE_DEVELOP_VERSION}"
}

function merge_release_branch_message {
    local branch_to_be_merged_to=$1
    echo "Merge branch '$RELEASE_BRANCH' into '$branch_to_be_merged_to'"
}
