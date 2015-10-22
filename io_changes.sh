# place for project specific io changes (bumping pom versions..)

function check_current_version {
    local expected_version=$1
    local xpath='/*[local-name()="project"]/*[local-name()="version"]/text()'
    local actual_version=`xmllint --xpath "$xpath" $GIT_ROOT/maven/pom.xml`
    if [ $actual_version != $expected_version ] ; then
        exit_safe 99 "Unexpected version $actual_version , expected was $expected_version"
    fi
}

function io_create_release {
    assert_current_branch_name $RELEASE_BRANCH
    local new_version=$RELEASE_VERSION
    update_versions $new_version
    echo remove_version_snapshot $new_version
    remove_version_snapshot $new_version
}

function io_future_develop {
    assert_current_branch_name $RELEASE_BRANCH
    local new_version=$FUTURE_DEVELOP_VERSION
    update_versions $new_version
    echo add_version_snapshot $new_version
    add_version_snapshot $new_version $RELEASE_VERSION
}

function update_versions {
    local new_version=$1
    cd $GIT_ROOT/maven
    mvn -o versions:set -DnewVersion=$new_version versions:commit
}

function io_hotfix_changes {
    assert_current_branch_name $HOTFIX_BRANCH
    update_versions "${FUTURE_HOTFIX_VERSION}"
    add_version_snapshot $FUTURE_HOTFIX_VERSION $RELEASE_VERSION
}

# private
function remove_version_snapshot {
    local expected_rpm_version=$1
    cd $GIT_ROOT/maven
    # rpm.version should be set already to $new_version
    egrep "<rpm.version>$expected_rpm_version</rpm.version>" pom.xml
    assert_success "Expected $expected_rpm_version inside rpm.version tag"
    egrep "<rpm.release>SNAPSHOT<\/rpm.release>" pom.xml
    assert_success "Expected SNAPSHOT inside rpm.release tag"
    sed -i "s/<rpm.release>SNAPSHOT<\/rpm.release>/\<rpm.release\>0\<\/rpm.release\>/" pom.xml
}

# private
function add_version_snapshot {
    local future_version=$1
    local expected_rpm_version=$2
    cd $GIT_ROOT/maven
    local future_version_core=${future_version%-*}
    egrep "<rpm.version>$expected_rpm_version</rpm.version>" pom.xml
    assert_success "Expected $expected_rpm_version inside rpm.version tag"
    egrep "<rpm.release>0<\/rpm.release>" pom.xml
    assert_success "Expected 0 inside rpm.release tag"

    sed -i "s/<rpm.version>$expected_rpm_version<\/rpm.version>/<rpm.version>$future_version_core<\/rpm.version>/" pom.xml
    sed -i "s/<rpm.release>0<\/rpm.release>/<rpm.release>SNAPSHOT<\/rpm.release>/" pom.xml
}
