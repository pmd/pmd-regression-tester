# 1.4.1-SNAPSHOT / ????-??-??

## New and Noteworthy

## Enhancements

## Fixed Issues

* [#104](https://github.com/pmd/pmd-regression-tester/issues/104): Baseline filtering is not working anymore

## External Contributions

# 1.4.0 / 2022-03-24

## Enhancements

*   [#103](https://github.com/pmd/pmd-regression-tester/pull/103): Support other languages besides java

# 1.3.0 / 2021-12-17

## Enhancements

*   [#94](https://github.com/pmd/pmd-regression-tester/issues/94): Improve code snippet preview
*   [#95](https://github.com/pmd/pmd-regression-tester/issues/95): Add length menu for datatable to allow configurable page size

## Fixed Issues

*   [#86](https://github.com/pmd/pmd-regression-tester/issues/86): Uncaught TypeError: violation is undefined
*   [#93](https://github.com/pmd/pmd-regression-tester/issues/93): Line numbers > 1000 are not displayed correctly
*   [#96](https://github.com/pmd/pmd-regression-tester/issues/96): Fix failing integration tests

# 1.2.0 / 2021-06-20

## New and Noteworthy

*   Support for Mercurial is removed. The only SCM supported in the project-list.xml is "git".

## Fixed Issues

*   [#71](https://github.com/pmd/pmd-regression-tester/issues/71): Include full PMD report
*   [#89](https://github.com/pmd/pmd-regression-tester/pull/89): Make it possible to select a subpath of cloned directory
*   [#91](https://github.com/pmd/pmd-regression-tester/pull/91): Filter baseline based on patch config

# 1.1.2 / 2021-04-20

This is a bugfix release.

## Fixed Issues

*   [#85](https://github.com/pmd/pmd-regression-tester/issues/85): HTML is not escaped in snippet preview
*   [#84](https://github.com/pmd/pmd-regression-tester/issues/84): Leading spaces are missing in code snippet preview

# 1.1.1 / 2021-01-15

This is a bugfix release.

## Fixed Issues

*   [#81](https://github.com/pmd/pmd-regression-tester/pull/81): Dynamically generated rulesets are not applied on diffs
*   [#82](https://github.com/pmd/pmd-regression-tester/pull/82): Summary hash uses wrong key names
*   An already built PMD binary was not reused in CI

# 1.1.0 / 2020-12-05

## New and Noteworthy

* At least ruby 2.7 is required.

* Typeresolution is now supported by two new tags in the project-list.xml file:
`build-command` and `auxclasspath-command`. For details, see pull request [#72](https://github.com/pmd/pmd-regression-tester/pull/72).

* As part of [#74](https://github.com/pmd/pmd-regression-tester/pull/74) runner now returns a single hash
  with the summarized values instead of multiple numbers:

```
summary = PmdTester::Runner.new(argv).run
puts summary
# {:errors=>{:new=>0, :removed=>0}, :violations=>{:new=>0, :removed=>0, :changed=>0}, :configerrors=>{:new=>0, :removed=>0}}
```

* As part of [#73](https://github.com/pmd/pmd-regression-tester/issues/73) and [#78](https://github.com/pmd/pmd-regression-tester/pull/78)
  a improved HTML report is now generated with the following features:
  * searchable table for violations with filters by rule/file/kind (added, removed, changed)
  * summary of changes by rule
  * code snippets for the violations

## Fixed Issues

*   [#48](https://github.com/pmd/pmd-regression-tester/issues/48): Support auxclasspath / typeresolution
*   [#67](https://github.com/pmd/pmd-regression-tester/pull/67): Report contains errors having nil filename
*   [#68](https://github.com/pmd/pmd-regression-tester/pull/68): Don't generate a dynamic ruleset if not needed
*   [#69](https://github.com/pmd/pmd-regression-tester/pull/69): Detect single rules with auto-gen-config
*   [#70](https://github.com/pmd/pmd-regression-tester/pull/70): Add link to PR on github in HTML report
*   [#73](https://github.com/pmd/pmd-regression-tester/issues/73): Better HTML presentation for diff report
*   [#74](https://github.com/pmd/pmd-regression-tester/pull/74): Merge violations that have just changed messages
*   [#75](https://github.com/pmd/pmd-regression-tester/pull/75): Add new option "--error-recovery"
*   [#76](https://github.com/pmd/pmd-regression-tester/pull/76): Speedup XML parsing
*   [#79](https://github.com/pmd/pmd-regression-tester/pull/79): Add new configuration option "--baseline-download-url"
*   [#80](https://github.com/pmd/pmd-regression-tester/pull/80): Cache and reuse pmd builds

## External Contributions

# 1.0.1 / 2020-07-08

This is a bugfix release.

## Fixed Issues

*   [#62](https://github.com/pmd/pmd-regression-tester/pull/62): Violation descriptions parsed incompletely

# 1.0.0 / 2020-04-25

## New and Noteworthy

First stable release.

## Fixed Issues

*   [#35](https://github.com/pmd/pmd-regression-tester/issues/35): exclude-pattern hasn't been implemented
*   [#37](https://github.com/pmd/pmd-regression-tester/issues/37): Render stack traces properly
*   [#38](https://github.com/pmd/pmd-regression-tester/issues/38): Improve Danger messages
*   [#40](https://github.com/pmd/pmd-regression-tester/issues/40): NoMethodError on beta3
*   [#42](https://github.com/pmd/pmd-regression-tester/issues/42): Installing the snapshot version of pmdtester locally from github
*   [#46](https://github.com/pmd/pmd-regression-tester/issues/46): Support multithreaded execution of PMD
*   [#47](https://github.com/pmd/pmd-regression-tester/issues/47): Reuse the already built PMD binary for PR checks
*   [#49](https://github.com/pmd/pmd-regression-tester/issues/49): Support comparing two error stacktraces
*   [#50](https://github.com/pmd/pmd-regression-tester/issues/50): Differences due to different locale settings
*   [#57](https://github.com/pmd/pmd-regression-tester/issues/57): Support configuration errors in the report
*   [#60](https://github.com/pmd/pmd-regression-tester/issues/60): Display a simple progress report

## External Contributions

*   [#33](https://github.com/pmd/pmd-regression-tester/pull/33): Ignore changes to test code of PMD when generating dynamic rule sets - [BBG](https://github.com/djydewang)
*   [#34](https://github.com/pmd/pmd-regression-tester/pull/34): Clear old reports before generating new differences regression reports - [BBG](https://github.com/djydewang)
*   [#36](https://github.com/pmd/pmd-regression-tester/pull/36): Implements exclude-pattern - [BBG](https://github.com/djydewang)
*   [#39](https://github.com/pmd/pmd-regression-tester/pull/39): Render stacktraces properly - [BBG](https://github.com/djydewang)
*   [#41](https://github.com/pmd/pmd-regression-tester/pull/41): Fixes NoMethodError in Project class - [BBG](https://github.com/djydewang)
*   [#43](https://github.com/pmd/pmd-regression-tester/pull/43): Adds pmdtester.gemspec file - [BBG](https://github.com/djydewang)
*   [#44](https://github.com/pmd/pmd-regression-tester/pull/44): Improve Danger messages & Increase the readability of the summary report - [BBG](https://github.com/djydewang)
*   [#45](https://github.com/pmd/pmd-regression-tester/pull/45): Removes the exit statement in RuleSetBuilder Class - [BBG](https://github.com/djydewang)
*   [#51](https://github.com/pmd/pmd-regression-tester/pull/51): Add the JDK version and locale info to the summary table of the diff report - [BBG](https://github.com/djydewang)
*   [#52](https://github.com/pmd/pmd-regression-tester/pull/52): Get the result of command 'java -version' from stderr rather than stdout - [BBG](https://github.com/djydewang)
*   [#53](https://github.com/pmd/pmd-regression-tester/pull/53): Support comparing the two error stacktraces - [BBG](https://github.com/djydewang)
*   [#54](https://github.com/pmd/pmd-regression-tester/pull/54): Support multithreaded execution of PMD - [BBG](https://github.com/djydewang)
*   [#61](https://github.com/pmd/pmd-regression-tester/pull/61): Display a simple progress report every 2 minutes - [BBG](https://github.com/djydewang)

# 1.0.0.beta3 / 2018-08-01

Note: This is a beta release. The pmdtester is feature complete,
but might contain bugs.

## External Contributions

*   [#28](https://github.com/pmd/pmd-regression-tester/pull/28): Refactor require statements - [BBG](https://github.com/djydewang)
*   [#29](https://github.com/pmd/pmd-regression-tester/pull/29): Add 'verify' rake task to verify code quality before committing changes - [BBG](https://github.com/djydewang)
*   [#30](https://github.com/pmd/pmd-regression-tester/pull/30): Fix diff_cmd in RuleSetBuilder - [BBG](https://github.com/djydewang)
*   [#31](https://github.com/pmd/pmd-regression-tester/pull/31): Fix color scheme for diff report, add default values for various options - [BBG](https://github.com/djydewang)
*   [#32](https://github.com/pmd/pmd-regression-tester/pull/32): Update Readme.rdoc - [BBG](https://github.com/djydewang)


# 1.0.0.beta2 / 2018-07-17

*   First release of pmdtester

Note: This is a beta release. The pmdtester is feature complete,
but might contains bugs.

## External Contributions

*   [#1](https://github.com/pmd/pmd-regression-tester/pull/1): Initialize project - [BBG](https://github.com/djydewang)
*   [#2](https://github.com/pmd/pmd-regression-tester/pull/2): Add projects parser & design format of projectlist - [BBG](https://github.com/djydewang)
*   [#3](https://github.com/pmd/pmd-regression-tester/pull/3): Add pmd report builder - [BBG](https://github.com/djydewang)
*   [#4](https://github.com/pmd/pmd-regression-tester/pull/4): Test PmdReportBuilder - [BBG](https://github.com/djydewang)
*   [#5](https://github.com/pmd/pmd-regression-tester/pull/5): Add DiffBuilder for PmdTester - [BBG](https://github.com/djydewang)
*   [#6](https://github.com/pmd/pmd-regression-tester/pull/6): Change the package command for building PMD - [BBG](https://github.com/djydewang)
*   [#7](https://github.com/pmd/pmd-regression-tester/pull/7): Add test cases for DiffBuilder - [BBG](https://github.com/djydewang)
*   [#8](https://github.com/pmd/pmd-regression-tester/pull/8): Add HtmlReportBuilder to PmdTester - [BBG](https://github.com/djydewang)
*   [#9](https://github.com/pmd/pmd-regression-tester/pull/9): Add test cases for HtmlReportBuilder - [BBG](https://github.com/djydewang)
*   [#10](https://github.com/pmd/pmd-regression-tester/pull/10): Add bundler to manage dependency - [BBG](https://github.com/djydewang)
*   [#11](https://github.com/pmd/pmd-regression-tester/pull/11): Using rubocop to check code style of the project - [BBG](https://github.com/djydewang)
*   [#12](https://github.com/pmd/pmd-regression-tester/pull/12): Fix Metrics/BlockLength offenses - [BBG](https://github.com/djydewang)
*   [#13](https://github.com/pmd/pmd-regression-tester/pull/13): Separate integration test cases - [BBG](https://github.com/djydewang)
*   [#14](https://github.com/pmd/pmd-regression-tester/pull/14): Add Runner to PmdTester - [BBG](https://github.com/djydewang)
*   [#15](https://github.com/pmd/pmd-regression-tester/pull/15): Fix rubocop Style/Documentation offenses - [BBG](https://github.com/djydewang)
*   [#16](https://github.com/pmd/pmd-regression-tester/pull/16): Add single mode, add mocha library for unit test - [BBG](https://github.com/djydewang)
*   [#17](https://github.com/pmd/pmd-regression-tester/pull/17): Add more details about pmd branchs and pmd reports - [BBG](https://github.com/djydewang)
*   [#18](https://github.com/pmd/pmd-regression-tester/pull/18): Add SummaryReportBuilder to PmdTester - [BBG](https://github.com/djydewang)
*   [#19](https://github.com/pmd/pmd-regression-tester/pull/19): Add online mode for PmdTester - [BBG](https://github.com/djydewang)
*   [#20](https://github.com/pmd/pmd-regression-tester/pull/20): Change the way of parsing xml file from DOM to SAX - [BBG](https://github.com/djydewang)
*   [#21](https://github.com/pmd/pmd-regression-tester/pull/21): Add auto-gen-config option for PmdTester - [BBG](https://github.com/djydewang)
*   [#22](https://github.com/pmd/pmd-regression-tester/pull/22): Add 'introduce new errors' table head for html summary report - [BBG](https://github.com/djydewang)
*   [#23](https://github.com/pmd/pmd-regression-tester/pull/23): Preparing for the release of PmdTester - [BBG](https://github.com/djydewang)
*   [#24](https://github.com/pmd/pmd-regression-tester/pull/24): Adding a logging framework for PmdTester - [BBG](https://github.com/djydewang)
*   [#25](https://github.com/pmd/pmd-regression-tester/pull/25): Remove working directory substring from filename of pmd violation - [BBG](https://github.com/djydewang)
*   [#26](https://github.com/pmd/pmd-regression-tester/pull/26): Release pmdtester 1.0.0.beta1 - [BBG](https://github.com/djydewang)
*   [#27](https://github.com/pmd/pmd-regression-tester/pull/27): Release pmdtester 1.0.0.beta2 - [BBG](https://github.com/djydewang)
