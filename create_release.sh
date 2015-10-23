#!/bin/bash
set -xe

# Branches $SOURCE_BRANCH,develop, rc, master must exist and be up to date.
# This script must be run from $SOURCE_BRANCH.
# Before running this script edit create_release_properties.sh
# Description:
# 1. create temporary release branch with name release/$RELEASE_VERSION
# 2. bump version to $RELEASE_VERSION
# 3. commit to release branch, then merge it into master
# 4. merge release into rc, with expected rc version (only if releasing from hotfix)
# 5. merge release (with changes to rc) into develop, with expected develop version
# 6. delete temporary release branch
# 7. create hotfix branch from master

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source $DIR/create_release_properties.sh
source $DIR/release_messages.sh
source $DIR/release_utils.sh
source $DIR/io_changes.sh

RELEASE_BRANCH="release/$RELEASE_VERSION"
GIT_ROOT=`git rev-parse --show-toplevel`

# checks start
assert_version_ends_with $EXPECTED_CURRENT_VERSION "SNAPSHOT"
assert_version_ends_with $EXPECTED_DEVELOP_VERSION "SNAPSHOT"
assert_version_ends_with $FUTURE_HOTFIX_VERSION "SNAPSHOT"
assert_version_ends_with $RELEASE_VERSION "0"
check_git_directories
check_release_tag_does_not_exist
io_check_current_version $EXPECTED_CURRENT_VERSION
git checkout develop
io_check_current_version $EXPECTED_DEVELOP_VERSION
if [ $SOURCE_BRANCH != "rc" ] ; then
    git checkout rc
    io_check_current_version $EXPECTED_RC_VERSION
fi
git checkout $SOURCE_BRANCH
# checks end

# 1.
git checkout -b $RELEASE_BRANCH
io_create_release
commit_changes "$(create_release_message)"
merge_release_branch_to "master"
tag_and_push_master
# 4.
if [ $SOURCE_BRANCH != "rc" ] ; then
    git checkout $RELEASE_BRANCH
    modify_version $RELEASE_VERSION "0" ${EXPECTED_RC_VERSION%-SNAPSHOT} "SNAPSHOT"
    commit_changes "$(bump_to_message $EXPECTED_RC_VERSION)"
    merge_release_branch_to "rc"
    push origin rc
fi
# 5.
git checkout $RELEASE_BRANCH
if [ $SOURCE_BRANCH != "rc" ] ; then
    # rc version should be expected
    modify_version ${EXPECTED_RC_VERSION%-SNAPSHOT} "SNAPSHOT" ${EXPECTED_DEVELOP_VERSION%-SNAPSHOT} "SNAPSHOT"
else
    modify_version $RELEASE_VERSION "0" ${EXPECTED_DEVELOP_VERSION%-SNAPSHOT} "SNAPSHOT"
fi
commit_changes "$(bump_to_message $EXPECTED_DEVELOP_VERSION)"
merge_release_branch_to "develop"
push origin develop
# 6.
git branch -d $RELEASE_BRANCH
# 7.
checkout_hotfix_branch_from_master
io_hotfix_changes
commit_changes "$(bump_to_message $FUTURE_HOTFIX_VERSION)"
push origin $HOTFIX_BRANCH
git checkout $SOURCE_BRANCH
