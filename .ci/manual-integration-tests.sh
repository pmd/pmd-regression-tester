#!/usr/bin/env bash

# Exit this script immediately if a command/function exits with a non-zero status.
set -e

SCRIPT_INCLUDES="log.bash utils.bash openjdk.bash"
# shellcheck source=inc/fetch_ci_scripts.bash
source "$(dirname "$0")/inc/fetch_ci_scripts.bash" && fetch_ci_scripts

function build() {
    pmd_ci_log_group_start "Install OpenJDK 8+11"
        pmd_ci_openjdk_install_adoptium 11
        pmd_ci_openjdk_install_adoptium 8
        pmd_ci_openjdk_setdefault 11
    pmd_ci_log_group_end

    pmd_ci_log_group_start "Install dependencies"
        gem install --user-install bundler
        bundle config set --local path vendor/bundle
        bundle install
    pmd_ci_log_group_end

    echo
    local version
    version="$(bundle exec ruby -I. -e 'require "lib/pmdtester"; print PmdTester::VERSION;')"
    pmd_ci_log_info "======================================================================="
    pmd_ci_log_info "Building pmd-regression-tester ${version}"
    pmd_ci_log_info "======================================================================="
    pmd_ci_utils_determine_build_env pmd/pmd-regression-tester
    echo

    pmd_ci_log_group_start "Run Manual Integration Tests"
        bundle exec ruby -I test test/manual_integration_tests.rb
    pmd_ci_log_group_end
}

build
