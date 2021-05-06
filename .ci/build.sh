#!/usr/bin/env bash

# Exit this script immediately if a command/function exits with a non-zero status.
set -e

SCRIPT_INCLUDES="log.bash utils.bash setup-secrets.bash openjdk.bash github-releases-api.bash"
# shellcheck source=inc/fetch_ci_scripts.bash
source "$(dirname "$0")/inc/fetch_ci_scripts.bash" && fetch_ci_scripts

function build() {
    pmd_ci_log_group_start "Install OpenJDK 8+11"
        pmd_ci_openjdk_install_adoptopenjdk 11
        pmd_ci_openjdk_install_adoptopenjdk 8
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

    pmd_ci_log_group_start "Build with rake"
        bundle exec rake check_manifest
        bundle exec rake rubocop
        bundle exec rake clean test
    pmd_ci_log_group_end

    pmd_ci_log_group_start "Run Integration Tests"
        bundle exec rake clean integration-test
    pmd_ci_log_group_end

    pmd_ci_log_group_start "Build Package"
        bundle exec rake install_gem
        bundle exec pmdtester -h
    pmd_ci_log_group_end

    if pmd_ci_utils_is_fork_or_pull_request; then
        # builds on forks or builds for pull requests stop here
        exit 0
    fi

    # only builds on pmd/pmd-regression-tester continue here
    pmd_ci_log_group_start "Setup environment"
        pmd_ci_setup_secrets_private_env
    pmd_ci_log_group_end

    if isReleaseBuild "$version"; then
        pmd_ci_log_group_start "Publish to rubygems"
            gem build pmdtester.gemspec
            local gempkgfile
            gempkgfile="$(echo pmdtester-*.gem)"
            gem push "${gempkgfile}"
        pmd_ci_log_group_end

        pmd_ci_log_group_start "Update Github Releases"
            # create a draft github release
            pmd_ci_gh_releases_createDraftRelease "${PMD_CI_TAG}" "$(git rev-list -n 1 "${PMD_CI_TAG}")"
            GH_RELEASE="$RESULT"

            # Deploy to github releases
            pmd_ci_gh_releases_uploadAsset "$GH_RELEASE" "${gempkgfile}"

            # extract the release notes
            RELEASE_NAME="${version}"
            BEGIN_LINE=$(grep -n "^# " History.md|head -1|cut -d ":" -f 1)
            BEGIN_LINE=$((BEGIN_LINE + 1))
            END_LINE=$(grep -n "^# " History.md|head -2|tail -1|cut -d ":" -f 1)
            END_LINE=$((END_LINE - 1))
            RELEASE_BODY="$(head -$END_LINE History.md | tail -$((END_LINE - BEGIN_LINE)))"

            pmd_ci_gh_releases_updateRelease "$GH_RELEASE" "$RELEASE_NAME" "$RELEASE_BODY"

            # Publish release - this sends out notifications on github
            pmd_ci_gh_releases_publishRelease "$GH_RELEASE"
        pmd_ci_log_group_end
    fi
}

function isReleaseBuild() {
    local version="$1"

    if [[ "${version}" != *-SNAPSHOT && "${PMD_CI_TAG}" != "" ]]; then
        return 0
    fi

    return 1
}

build
