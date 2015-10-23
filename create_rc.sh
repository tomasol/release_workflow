#!/bin/bash
set -xe

# Branches $SOURCE_BRANCH,develop, rc, master must exist and be up to date.
# This script must be run from $SOURCE_BRANCH.
# Before running this script edit create_rc_properties.sh
# Description:
# 1. switch from develop to rc
# 2. merge develop into rc
# 3. switch to develop,
# 4. bump version to FUTURE_DEVELOP_VERSION
# 5. commit to develop

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source $DIR/create_rc_properties.sh
source $DIR/release_messages.sh
source $DIR/release_utils.sh
source $DIR/io_changes.sh

GIT_ROOT=`git rev-parse --show-toplevel`

# checks start
assert_version_ends_with $EXPECTED_CURRENT_VERSION "SNAPSHOT"
assert_version_ends_with $FUTURE_DEVELOP_VERSION "SNAPSHOT"
# check that we are on develop branch
assert_current_branch_name develop
check_git_directories
io_check_current_version $EXPECTED_CURRENT_VERSION
# checks end

git checkout rc
git merge develop --no-ff -m "$(create_release_candidate_message)"
git push
# go to develop again
git checkout develop

io_bump_develop_after_rc
commit_changes "$(bump_to_message $FUTURE_DEVELOP_VERSION)"
git push
