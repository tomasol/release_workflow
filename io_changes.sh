function io_check_current_version {
    local expected_version=$1
    _io_check_current_version $expected_version
}

function io_create_release {
    assert_current_branch_name $RELEASE_BRANCH

    _modify_version ${EXPECTED_CURRENT_VERSION%-SNAPSHOT} "SNAPSHOT" $RELEASE_VERSION "0"
}

function io_from_release_to_snapshot {
    local future_snapshot_version=$1
    assert_current_branch_name $RELEASE_BRANCH
    assert_version_ends_with $RELEASE_VERSION "0"
    assert_version_ends_with $future_snapshot_version "SNAPSHOT"

    _modify_version $RELEASE_VERSION "0" ${future_snapshot_version%-SNAPSHOT} "SNAPSHOT"
}

function io_hotfix_changes {
    assert_current_branch_name $HOTFIX_BRANCH
    assert_version_ends_with $RELEASE_VERSION "0"
    assert_version_ends_with $FUTURE_HOTFIX_VERSION "SNAPSHOT"

    _modify_version $RELEASE_VERSION "0" ${FUTURE_HOTFIX_VERSION%-SNAPSHOT} "SNAPSHOT"
}

function io_bump_develop_after_rc {
    assert_current_branch_name 'develop'
    assert_version_ends_with $EXPECTED_CURRENT_VERSION "SNAPSHOT"
    assert_version_ends_with $FUTURE_DEVELOP_VERSION "SNAPSHOT"

    _modify_version ${EXPECTED_CURRENT_VERSION%-SNAPSHOT} "SNAPSHOT" ${FUTURE_DEVELOP_VERSION%-SNAPSHOT} "SNAPSHOT"
}

# private and specific io changes for project

function _io_check_current_version {
    local expected_version=$1
    local xpath='/*[local-name()="project"]/*[local-name()="version"]/text()'
    local actual_version
    actual_version=`xmllint --xpath "$xpath" $GIT_ROOT/maven/pom.xml`
    if [ $actual_version != $expected_version ] ; then
        exit_safe 99 "Unexpected version $actual_version , expected was $expected_version"
    fi
}

function _modify_version {
    local expected_version_core=$1
    local expected_rpm_release=$2  # SNAPSHOT or 0
    local future_version_core=$3
    local future_rpm_release=$4    # SNAPSHOT or 0

    local expected_maven_version=$expected_version_core
    if [ $expected_rpm_release == "SNAPSHOT" ] ; then
        expected_maven_version="$expected_maven_version-SNAPSHOT"
    fi

    # checks
    _io_check_current_version $expected_maven_version
    local pom_path=$GIT_ROOT/maven/pom.xml
    set +e
    egrep "<rpm.version>$expected_version_core</rpm.version>" $pom_path
    assert_success "Expected $expected_version_core inside rpm.version tag"
    egrep "<rpm.release>$expected_rpm_release<\/rpm.release>" $pom_path
    assert_success "Expected $expected_rpm_release inside rpm.release tag"
    set -e

    # replace rpm version
    sed -i "s/<rpm.version>$expected_version_core<\/rpm.version>/<rpm.version>$future_version_core<\/rpm.version>/" $pom_path
    sed -i "s/<rpm.release>$expected_rpm_release<\/rpm.release>/<rpm.release>$future_rpm_release<\/rpm.release>/" $pom_path

    local future_maven_version=$future_version_core
    if [ $future_rpm_release == "SNAPSHOT" ] ; then
        future_maven_version="$future_maven_version-SNAPSHOT"
    fi
    # replace maven version
    (cd $GIT_ROOT/maven && mvn -o versions:set -DnewVersion=$future_maven_version versions:commit)
}
