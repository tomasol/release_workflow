#!/bin/bash

ORIGIN_REMOTE=origin
EXPECTED_CURRENT_VERSION="2.14.3-SNAPSHOT"
# hotfix branch does not have to exist
HOTFIX_BRANCH="2.14.x"
# source branch should be either develop or hotfix branch
SOURCE_BRANCH="$HOTFIX_BRANCH"
# should be derived from $EXPECTED_CURRENT_VERSION
RELEASE_VERSION="2.14.3"
FUTURE_DEVELOP_VERSION="2.15.0-SNAPSHOT"
# do not forget to add -SNAPSHOT here:
FUTURE_HOTFIX_VERSION="2.14.4-SNAPSHOT"
