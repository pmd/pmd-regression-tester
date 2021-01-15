#!/usr/bin/env bash

source $(dirname $0)/inc/install-openjdk.inc

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
