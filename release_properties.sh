#!/bin/bash

ORIGIN_BRANCH=origin
EXPECTED_CURRENT_VERSION="2.14.0-SNAPSHOT"
# hotfix branch does not have to exist
HOTFIX_BRANCH="2.14.x"
# source branch should be either develop or hotfix branch
SOURCE_BRANCH="develop"
RELEASE_VERSION="2.14.1"
FUTURE_DEVELOP_VERSION="2.15.0-SNAPSHOT"
# do not forget to add -SNAPSHOT here:
FUTURE_HOTFIX_VERSION="2.14.1-SNAPSHOT"
