# hotfix branch will be created if $SOURCE_BRANCH is rc
HOTFIX_BRANCH="2.27.x"
# SOURCE_BRANCH must be set to rc or $HOTFIX_BRANCH
SOURCE_BRANCH="$HOTFIX_BRANCH"
# EXPECTED_CURRENT_VERSION must be equal to current $SOURCE_BRANCH version
EXPECTED_CURRENT_VERSION="2.27.1-SNAPSHOT"
# current develop version
EXPECTED_DEVELOP_VERSION="2.29.0-SNAPSHOT"
# EXPECTED_RC_VERSION must be set only if creating hotfix release
EXPECTED_RC_VERSION="2.28.0-SNAPSHOT"
# next hotfix version, do not forget to add -SNAPSHOT here:
FUTURE_HOTFIX_VERSION="2.27.2-SNAPSHOT"

# Removes -SNAPSHOT from EXPECTED_CURRENT_VERSION
RELEASE_VERSION=${EXPECTED_CURRENT_VERSION%-SNAPSHOT}
