#!/bin/bash

function check_current_version {
    local expected_version=$1
    local xpath='/*[local-name()="project"]/*[local-name()="version"]/text()'
    local actual_version=`xmllint --xpath "$xpath" $GIT_ROOT/_ASSEMBLY_/Install/rpm/pom.xml`
    if [ $actual_version != $expected_version ] ; then
        exit_safe 99 "Unexpected version $actual_version , expected was $expected_version"
    fi
}

function check_compile {
    cd $GIT_ROOT/_ASSEMBLY_/Build
    mvn clean install -T 3 -e
    assert_success
    cd $GIT_ROOT/_ASSEMBLY_/Install/rpm
    mvn clean install -T 3 -e
    assert_success
    cd $GIT_ROOT/WRMI
    grails compile
    assert_success
}

function io_create_release {
    assert_current_branch_name $RELEASE_BRANCH
    local new_version=$RELEASE_VERSION
    update_versions $new_version
    echo remove_version_snapshot $new_version
    remove_version_snapshot $new_version
    # this might produce no change if source branch != develop:
    change_ci_db "CI-DEVELOP" "CI-MASTER"
}

function io_future_develop {
    assert_current_branch_name $RELEASE_BRANCH
    local new_version=$FUTURE_DEVELOP_VERSION
    update_versions $new_version
    echo add_version_snapshot $new_version
    local expected_rpm_version_if_adding=$RELEASE_VERSION
    add_version_snapshot $new_version $expected_rpm_version_if_adding
    change_ci_db "CI-MASTER" "CI-DEVELOP"
}

function update_versions {
    local new_version=$1
    cd $GIT_ROOT/_ASSEMBLY_/Build
    mvn -o versions:set -DnewVersion=$new_version versions:commit

    cd $GIT_ROOT/_ASSEMBLY_/Install/rpm
    mvn -o versions:set -DnewVersion=$new_version versions:commit

    cd $GIT_ROOT/WRMI
    sed -i 's/^app.version.*/app.version='$new_version'/' application.properties
    sed -i 's/^version.tbo.*/version.tbo = "'$new_version'"/' grails-app/conf/BuildConfig.groovy
}

function io_hotfix_changes {
    assert_current_branch_name $HOTFIX_BRANCH
    update_versions "${FUTURE_HOTFIX_VERSION}"
    add_version_snapshot $FUTURE_HOTFIX_VERSION $RELEASE_VERSION
}

# private
function remove_version_snapshot {
    local expected_rpm_version=$1
    cd $GIT_ROOT/_ASSEMBLY_/Install/rpm
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
    cd $GIT_ROOT/_ASSEMBLY_/Install/rpm
    local future_version_core=${future_version%-*}
    egrep "<rpm.version>$expected_rpm_version</rpm.version>" pom.xml
    assert_success "Expected $expected_rpm_version inside rpm.version tag"
    egrep "<rpm.release>0<\/rpm.release>" pom.xml
    assert_success "Expected 0 inside rpm.release tag"

    sed -i "s/<rpm.version>$expected_rpm_version<\/rpm.version>/<rpm.version>$future_version_core<\/rpm.version>/" pom.xml
    sed -i "s/<rpm.release>0<\/rpm.release>/<rpm.release>SNAPSHOT<\/rpm.release>/" pom.xml
}

#private
function change_ci_db() {
    local old_db_user=$1
    local new_db_user=$2
    cd $GIT_ROOT
    sed -i "s/<test.database.group.username>$old_db_user<\/test.database.group.username>/<test.database.group.username>$new_db_user<\/test.database.group.username>/" Data-Service-Group/pom.xml
    sed -i "s/<test.database.outlet.username>$old_db_user<\/test.database.outlet.username>/<test.database.outlet.username>$new_db_user<\/test.database.outlet.username>/" Data-Service-Outlet/pom.xml
}
