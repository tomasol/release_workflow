#!/bin/bash

function check_compile {
    cd $GIT_ROOT/_ASSEMBLY_/Build
    mvn clean install -T 3 -e

    cd $GIT_ROOT/_ASSEMBLY_/Install/rpm
    mvn clean install -T 3 -e

    cd $GIT_ROOT/WRMI
    grails compile
}

function io_changes {
    local create_release=$1
    assert_current_branch_name $RELEASE_BRANCH
    if [ $create_release = true ] ; then
        local new_version=$RELEASE_VERSION
        update_versions $new_version
        echo remove_version_snapshot $new_version
        remove_version_snapshot $new_version
        # this might produce no change if source branch != develop:
        change_ci_db "CI-DEVELOP" "CI-MASTER"
    else
        local new_version=$FUTURE_DEVELOP_VERSION
        update_versions $new_version
        echo add_version_snapshot $new_version
        local expected_rpm_version_if_adding=$RELEASE_VERSION
        add_version_snapshot $new_version $expected_rpm_version_if_adding
        change_ci_db "CI-MASTER" "CI-DEVELOP"
    fi
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
