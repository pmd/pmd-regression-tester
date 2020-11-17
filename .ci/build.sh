#!/usr/bin/env bash

set -e


function build_regression_tester() {
    echo "::group::Install OpenJDK 8+11"
    install_openjdk 8
    install_openjdk 11 # last one is the default
    echo "::endgroup::"

    echo "::group::Install dependencies"
    gem install bundler
    bundle config set --local path vendor/bundle
    bundle install
    echo "::endgroup::"

    echo "::group::Build with rake"
    bundle exec rake check_manifest
    bundle exec rake rubocop
    bundle exec rake clean test
    echo "::endgroup::"

    echo "::group::Run Integration Tests"
    bundle exec rake clean integration-test
    echo "::endgroup::"

    echo "::group::Build Package"
    bundle exec rake install_gem
    bundle exec pmdtester -h
    echo "::endgroup::"

    # builds on forks or builds for pull requests stop here
    if [[ "${PMD_CI_REPO}" != "pmd/pmd-regression-tester" || -n "${PMD_CI_PULL_REQUEST_NUMBER}" ]]; then
        exit 0
    fi

    # if this is a release build from a tag...
    if [[ "${PMD_CI_REPO}" == "pmd/pmd-regression-tester" && "${PMD_CI_GIT_REF}" == refs/tags/* ]]; then
        echo "::group::Publish to rubygems"
        setup_secrets

        git stash --all
        gem build pmdtester.gemspec
        gem push pmdtester-*.gem
        echo "::endgroup::"
    fi

}

## helper functions

function install_openjdk() {
    OPENJDK_VERSION=$1
    echo "Installing OpenJDK ${OPENJDK_VERSION}"
    JDK_OS=linux
    COMPONENTS_TO_STRIP=1 # e.g. openjdk-11.0.3+7/bin/java
    DOWNLOAD_URL=$(curl --silent -X GET "https://api.adoptopenjdk.net/v3/assets/feature_releases/${OPENJDK_VERSION}/ga?architecture=x64&heap_size=normal&image_type=jdk&jvm_impl=hotspot&os=${JDK_OS}&page=0&page_size=1&project=jdk&sort_method=DEFAULT&sort_order=DESC&vendor=adoptopenjdk" \
        -H "accept: application/json" \
        | jq -r ".[0].binaries[0].package.link")
    OPENJDK_ARCHIVE=$(basename ${DOWNLOAD_URL})
    CACHE_DIR=${HOME}/.cache/openjdk
    TARGET_DIR=${HOME}/openjdk${OPENJDK_VERSION}
    mkdir -p ${CACHE_DIR}
    mkdir -p ${TARGET_DIR}
    if [ ! -e ${CACHE_DIR}/${OPENJDK_ARCHIVE} ]; then
        echo "Downloading from ${DOWNLOAD_URL} to ${CACHE_DIR}"
        curl --location --output ${CACHE_DIR}/${OPENJDK_ARCHIVE} "${DOWNLOAD_URL}"
    else
        echo "Skipped download, file ${CACHE_DIR}/${OPENJDK_ARCHIVE} already exists"
    fi
    tar --extract --file ${CACHE_DIR}/${OPENJDK_ARCHIVE} -C ${TARGET_DIR} --strip-components=${COMPONENTS_TO_STRIP}
    export JAVA_HOME="${TARGET_DIR}"
    export PATH="${TARGET_DIR}/bin:${PATH}"
    java -version
    echo "Java is available at ${TARGET_DIR}"
}

function setup_secrets() {
    echo "Setting up secrets..."
    # Required secrets are: GEM_HOST_API_KEY
    local -r env_file=".ci/files/env"
    printenv PMD_CI_SECRET_PASSPHRASE | gpg --batch --yes --decrypt \
        --passphrase-fd 0 \
        --output ${env_file} ${env_file}.gpg
    source ${env_file} >/dev/null 2>&1
    rm ${env_file}
}


build_regression_tester
