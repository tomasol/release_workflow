#!/bin/bash

# Before running this script edit release_properties.sh,
# update your master, develop and possibly hotfix branch.
# Switch to $SOURCE_BRANCH, otherwise this script will exit prematurely.
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source $DIR/release_properties.sh
source $DIR/release_messages.sh
source $DIR/release_utils.sh
source $DIR/io_changes.sh

RELEASE_BRANCH="release/$RELEASE_VERSION"
GIT_ROOT=`git rev-parse --show-toplevel`


check_git_directories
check_release_tag_does_not_exist
check_current_version $EXPECTED_CURRENT_VERSION
create_release_branch
io_changes true
check_compile
commit_changes "$(create_release_message)"
merge_release_branch_to "master"
tag_and_push_master

checkout_release_branch
io_changes false
check_compile
commit_changes "$(bump_to_future_develop_message)"
merge_release_branch_to "develop"
push_develop_and_delete_release_branch

checkout_hotfix_branch_from_master
io_hotfix_changes
commit_push_hotfix_branch
checkout_source_branch
