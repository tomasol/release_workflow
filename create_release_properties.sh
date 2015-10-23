# hotfix branch will be created if $SOURCE_BRANCH is rc
HOTFIX_BRANCH="2.24.x"
# SOURCE_BRANCH must be set to rc or $HOTFIX_BRANCH
SOURCE_BRANCH="rc"
# EXPECTED_CURRENT_VERSION must be equal to current $SOURCE_BRANCH version
EXPECTED_CURRENT_VERSION="2.24.0-SNAPSHOT"
# current develop version
EXPECTED_DEVELOP_VERSION="2.25.0-SNAPSHOT"
# EXPECTED_RC_VERSION must be set only if creating hotfix release
EXPECTED_RC_VERSION=...
# next hotfix version, do not forget to add -SNAPSHOT here:
FUTURE_HOTFIX_VERSION="2.24.1-SNAPSHOT"

# Removes -SNAPSHOT from EXPECTED_CURRENT_VERSION
RELEASE_VERSION=${EXPECTED_CURRENT_VERSION%-SNAPSHOT}
