#!/usr/bin/env bash

source $(dirname $0)/inc/install-openjdk.inc

set -e

echo "::group::Install OpenJDK 8+11"
install_openjdk 8
install_openjdk 11 # last one is the default
echo "::endgroup::"

echo "::group::Install dependencies"
gem install bundler
bundle config set --local path vendor/bundle
bundle install
echo "::endgroup::"

echo "::group::Run Manual Integration Tests"
bundle exec ruby -I test test/manual_integration_tests.rb
echo "::endgroup::"
