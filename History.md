# 1.0.0-SNAPSHOT / 2018-08-??

## New and Noteworthy

## Fixed Issues

*   [#35](https://github.com/pmd/pmd-regression-tester/issues/35): exclude-pattern hasn't been implemented
*   [#37](https://github.com/pmd/pmd-regression-tester/issues/37): Render stack traces properly
*   [#38](https://github.com/pmd/pmd-regression-tester/issues/38): Improve Danger messages
*   [#40](https://github.com/pmd/pmd-regression-tester/issues/40): NoMethodError on beta3
*   [#42](https://github.com/pmd/pmd-regression-tester/issues/42): Installing the snapshot version of pmdtester locally from github
*   [#46](https://github.com/pmd/pmd-regression-tester/issues/46): Support multithreaded execution of PMD
*   [#49](https://github.com/pmd/pmd-regression-tester/issues/49): Support comparing two error stacktraces
*   [#50](https://github.com/pmd/pmd-regression-tester/issues/50): Differences due to different locale settings

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
