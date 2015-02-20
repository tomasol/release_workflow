#!/bin/bash

# Do not exit if running from console
function exit_safe {
    local exit_status=$1
    local exit_message=$2
    if [ -z "$exit_status" ]; then
        exit_status=99
    fi
    if [ -n "$exit_message" ]; then
        echo -e "$exit_message"
    fi
    echo "Failure with status code $exit_status. Press Ctrl-C to stop, Ctrl-D to ignore and continue"
    cat
}

function assert_success {
    local previous_command_exit_status=$?
    local error_message=$1
    local intended_exit_status=$2
    if [ -z "$error_message" ]; then
        error_message="Last command failed"
    fi
    if [ -z "$intended_exit_status" ]; then
        intended_exit_status=9
    fi
    if [ $previous_command_exit_status != 0 ] ; then
        exit_safe $intended_exit_status "$error_message"
    fi
}

function assert_current_branch_name {
    local expected_branch_name=$1
    local current_branch_name=`git rev-parse --abbrev-ref HEAD`
    if [ $current_branch_name != $expected_branch_name ] ; then
        exit_safe 3 "Expected to be on $expected_branch_name, got $current_branch_name"
    fi
}

# Local changes or adding files to staging area will fail this test
function assert_clean_copy {
    git status | grep "nothing to commit" > /dev/null 2>&1;
    assert_success "Expected this local branch to be clean"
}

# Check that $branch is up to date with its $ORIGIN_REMOTE, expects git fetch to be called previously
function assert_branch_is_up_to_date {
    local branch=$1
    local last_remote_commit=`git rev-parse $ORIGIN_REMOTE/$branch`
    local last_local_commit=`git rev-parse $branch`
    if [ $last_remote_commit != $last_local_commit ]; then
        exit_safe 9 "Remote branch has different tip than local for branch '$branch'. \n\
        last_remote_commit = $last_remote_commit \n\
        last_local_commit  = $last_local_commit
        "
    fi
}


# Check that current branch is $SOURCE_BRANCH, it is clean and up to date.
# Also check that develop and master are up to date
function check_git_directories {
    if [ -z "$GIT_ROOT" ] ; then
        exit_safe 1 "No git root found."
    fi
    echo "Git root found: $GIT_ROOT"
    git fetch $ORIGIN_REMOTE
    # local branch should be $SOURCE_BRANCH
    assert_current_branch_name $SOURCE_BRANCH
    assert_clean_copy
    assert_branch_is_up_to_date $SOURCE_BRANCH
    assert_branch_is_up_to_date develop
    assert_branch_is_up_to_date master
}

function check_release_tag_does_not_exist {
    local found_tag=`git tag | grep $RELEASE_VERSION`
    if [ "$found_tag" == "$RELEASE_VERSION" ] ; then
        exit_safe 5 "Tag $RELEASE_VERSION already exists, not going to release."
    fi
}

function create_release_branch {
    git checkout -b $RELEASE_BRANCH
    assert_success "Failed to create '$RELEASE_BRANCH' branch" 1
}

function commit_changes() {
    local message=$1
    git commit -a -m "$message"
    assert_clean_copy
}

# merge current branch to master
function merge_release_branch_to {
    local branch_to_be_merged_to=$1
    git checkout $branch_to_be_merged_to
    git merge --no-ff $RELEASE_BRANCH -m "$(merge_release_branch_message $branch_to_be_merged_to)"
    assert_success
}

function tag_and_push_master {
    git tag -a $RELEASE_VERSION -m "$(tag_message)"
    push_interactive
    assert_success
    push_interactive --tags $ORIGIN_REMOTE
    assert_success
}

function checkout_release_branch {
    git checkout $RELEASE_BRANCH
}

function push_develop_and_delete_release_branch {
    push_interactive $ORIGIN_REMOTE develop
    assert_success
    git branch -d $RELEASE_BRANCH
}

function checkout_hotfix_branch_from_master {
    git checkout master
    git checkout -B $HOTFIX_BRANCH
}

function push_hotfix_branch {
    push_interactive $ORIGIN_REMOTE $HOTFIX_BRANCH
    assert_success
}

function checkout_source_branch {
    git checkout $SOURCE_BRANCH
}

function push_interactive {
    local args=$*
    local current_branch_name=`git rev-parse --abbrev-ref HEAD`
    echo "About to push '$current_branch_name'"
    echo "Press Ctrl-C to stop, Ctrl-D to continue"
    cat
    git push $args
}
