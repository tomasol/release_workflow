#!/bin/bash
set -xe

# Branches $SOURCE_BRANCH,develop, rc, master must exist and be up to date.
# This script must be run from $SOURCE_BRANCH.
# Before running this script edit create_release_properties.sh
# Description:
# 1. create temporary release branch with name release/$RELEASE_VERSION
# 2. bump version to $RELEASE_VERSION
# 3. commit to release branch, then merge it into master
# 4. merge release into develop, with expected develop version
# 5. create hotfix branch from master

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source $DIR/create_release_properties.sh
source $DIR/release_messages.sh
source $DIR/release_utils.sh
source $DIR/io_changes.sh

RELEASE_BRANCH="release/$RELEASE_VERSION"
GIT_ROOT=`git rev-parse --show-toplevel`

# checks start
assert_version_ends_with $EXPECTED_CURRENT_VERSION "SNAPSHOT"
assert_version_ends_with $FUTURE_DEVELOP_VERSION "SNAPSHOT"
assert_version_ends_with $FUTURE_HOTFIX_VERSION "SNAPSHOT"
assert_version_ends_with $RELEASE_VERSION "0"
check_git_directories
check_release_tag_does_not_exist
io_check_current_version $EXPECTED_CURRENT_VERSION
# checks end

# 1.
git checkout -b $RELEASE_BRANCH
io_create_release
commit_changes "$(create_release_message)"
merge_release_branch_to "master"
tag_and_push_master
# 4.
checkout_release_branch
io_future_develop
commit_changes "$(bump_to_future_develop_message)"
merge_release_branch_to "develop"
push_develop_and_delete_release_branch
# 5.
checkout_hotfix_branch_from_master
io_hotfix_changes
commit_changes "$(bump_to_future_hotfix_message)"
push_hotfix_branch
checkout_source_branch
