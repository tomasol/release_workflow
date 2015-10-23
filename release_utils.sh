function exit_safe {
    local exit_status=$1
    local exit_message=$2
    if [ -z "$exit_status" ]; then
        exit_status=99
    fi
    if [ -n "$exit_message" ]; then
        echo -e "$exit_message"
    fi
    # hack to avoid closing of terminal when pasting functions to bash
    local path_to_bash
    path_to_bash=`which bash`
    if [ "$path_to_bash" == $0 ]; then
      echo "Not exitting with status code $exit_status. Press Ctrl-C to stop, Ctrl-D to ignore and continue"
      cat
    else
      echo "Exitting with status code $exit_status."
      exit $exit_status
    fi
}

function assert_success {
    local previous_command_exit_status=$?
    local error_message=$1
    local intended_exit_status=$2
    if [ -z "$error_message" ]; then
        error_message="Last command failed"
    fi
    if [ -z "$intended_exit_status" ]; then
        intended_exit_status=$previous_command_exit_status
    fi
    if [ $previous_command_exit_status != 0 ] ; then
        exit_safe $intended_exit_status "$error_message"
    fi
}

function assert_current_branch_name {
    local expected_branch_name=$1
    local current_branch_name
    current_branch_name=`git rev-parse --abbrev-ref HEAD`
    if [ $current_branch_name != $expected_branch_name ] ; then
        exit_safe 3 "Expected to be on $expected_branch_name, got $current_branch_name"
    fi
}

# Local changes or adding files to staging area will fail this test
function assert_clean_copy {
    set +e
    git status | grep "nothing to commit" > /dev/null 2>&1;
    assert_success "Please commit and push local changes"
    set -e
}

# Check that $branch is up to date with its origin, expects git fetch to be called previously
function assert_branch_is_up_to_date {
    local branch=$1
    local last_remote_commit
    last_remote_commit=`git rev-parse origin/$branch`
    local last_local_commit
    last_local_commit=`git rev-parse $branch`
    if [ $last_remote_commit != $last_local_commit ]; then
        exit_safe 9 "Remote branch has different tip than local for branch '$branch'. \n\
        last_remote_commit = $last_remote_commit \n\
        last_local_commit  = $last_local_commit
        "
    fi
}

function assert_version_ends_with {
    local value=$1
    local snapshot_or_zero=$2 # only "SNAPSHOT" or '0' are valid
    if [ $snapshot_or_zero == "SNAPSHOT" ] ; then
        set +e
        echo $value | grep '\-SNAPSHOT$' > /dev/null
        assert_success "assert_version_ends_with: Wrong value $value for validation parameter $snapshot_or_zero"
        set -e
    elif [ $snapshot_or_zero == "0" ] ; then
        set +e
        echo $value | grep '\-' > /dev/null
        if [ $? != "1" ] ; then
            exit_safe 1 "assert_version_ends_with: Wrong value $value for validation parameter $snapshot_or_zero"
        fi
        set -e
    else
        exit_safe 1 "assert_version_ends_with: Invalid parameter $1, expected SNAPSHOT or 0"
    fi
}

# Check that current branch is $SOURCE_BRANCH, it is clean and up to date.
# Also check that develop and master are up to date
function check_git_directories {
    if [ -z "$GIT_ROOT" ] ; then
        exit_safe 1 "No git root found."
    fi
    echo "Git root found: $GIT_ROOT"
    git fetch origin
    # local branch should be $SOURCE_BRANCH
    assert_current_branch_name $SOURCE_BRANCH
    assert_clean_copy
    assert_branch_is_up_to_date $SOURCE_BRANCH
    assert_branch_is_up_to_date develop
    assert_branch_is_up_to_date rc
    assert_branch_is_up_to_date master
}

function check_release_tag_does_not_exist {
    local found_tag
    set +e
    found_tag=`git tag | grep $RELEASE_VERSION`
    if [ "$found_tag" == "$RELEASE_VERSION" ] ; then
        exit_safe 5 "Tag $RELEASE_VERSION already exists, not going to release."
    fi
    set -e
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
}

function tag_and_push_master {
    git tag -a $RELEASE_VERSION -m "$(tag_message)"
    push
    push --tags origin
}

function checkout_hotfix_branch_from_master {
    git checkout master
    git checkout -B $HOTFIX_BRANCH
}

function push {
    local args=$*
    local current_branch_name
    current_branch_name=`git rev-parse --abbrev-ref HEAD`
    echo "About to push '$current_branch_name': git push $args"
    git push $args
}
