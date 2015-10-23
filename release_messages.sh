function tag_message {
    echo "TBO Services release $RELEASE_VERSION."
}

function create_release_message {
    echo "Create release $RELEASE_VERSION"
}

function bump_to_message {
    echo "Bump version to $1"
}

function merge_release_branch_message {
    local branch_to_be_merged_to=$1
    echo "Merge branch '$RELEASE_BRANCH' into '$branch_to_be_merged_to'"
}

function create_release_candidate_message {
    echo "Create new release candidate from $EXPECTED_CURRENT_VERSION"
}
