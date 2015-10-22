!#/bin/bash
set -x

# inputs:
# SOURCE_BRANCH must be set to develop
# EXPECTED_CURRENT_VERSION must be equal to current develop version
# FUTURE_DEVELOP_VERSION
# develop, rc branch must exist and be up to date


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source $DIR/release_properties.sh
source $DIR/release_messages.sh
source $DIR/release_utils.sh
source $DIR/io_changes.sh

GIT_ROOT=`git rev-parse --show-toplevel`

# chek that we are on develop branch
assert_current_branch_name develop
check_git_directories
io_check_current_version $EXPECTED_CURRENT_VERSION

#TODO
check_rc_branch # it must have been pushed, in current state
merge_develop_to_rc_branch
# go to develop again
io_bump_develop
commit_changes "$(bump_develop_message)"
