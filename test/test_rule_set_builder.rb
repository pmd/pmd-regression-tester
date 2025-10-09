# frozen_string_literal: true

require 'test_helper'

# The unit test class for RuleSetBuilder
class TestRuleSetBuilder < Test::Unit::TestCase
  PATH_TO_TEST_RESOURCES = 'test/resources/rule_set_builder'
  include PmdTester

  def cleanup
    filename = RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG
    FileUtils.rm_rf filename
  end

  def mock_build?(diff_filenames, filter_set = nil, patch_config = nil)
    options = mock
    options.expects(:patch_config).returns(Options::DEFAULT_CONFIG_PATH)
    options.expects(:local_git_repo).returns("#{PATH_TO_TEST_RESOURCES}/partial-pmd-repo").twice
    options.expects(:base_branch).returns('base_branch')
    options.expects(:patch_branch).returns('patch_branch')
    options.expects(:filter_set=).with(filter_set)
    if patch_config
      options.expects(:base_config).returns('')
      options.expects(:patch_config).returns(patch_config)
    else
      options.expects(:base_config=).with('target/dynamic-config.xml')
      options.expects(:patch_config=).with('target/dynamic-config.xml')
    end
    options.expects(:mode).returns('local').at_most_once
    builder = RuleSetBuilder.new(options)
    Cmd.expects(:execute_successfully).returns(diff_filenames)
    builder.build?
  end

  def test_build_design_codestyle_config
    diff_filenames = <<~DOC
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/design/NcssCountRule.java
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/codestyle/UnnecessaryReturnValueRule.java
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/codestyle/UnnecessaryConstructorRule.java
    DOC
    mock_build?(diff_filenames, Set['java/design.xml/NcssCount', 'java/codestyle.xml/UnnecessaryReturnValue',
                                    'java/codestyle.xml/UnnecessaryConstructor'])

    expected = File.read("#{PATH_TO_TEST_RESOURCES}/expected-design-codestyle.xml")
    actual = File.read(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG)
    assert_equal(expected, actual)
  end

  def test_build_all_rulesets_config_internal_abstract_class_changed
    # AbstractJavaRulechainRule is not a rule but an abstract base class for real rules. It lives
    # in an internal package. "internal" is not a valid ruleset category.
    diff_filenames = <<~DOC
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/internal/AbstractJavaRulechainRule.java
    DOC
    mock_build?(diff_filenames, nil, "#{PATH_TO_TEST_RESOURCES}/patch-ruleset.xml")

    assert(!File.exist?(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG),
           "File #{RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG} must not exist")
  end

  def test_build_all_rulesets_config_abstract_class_changed
    # AbstractNamingConventionRule is not a rule despite its name, it an abstract base class for real rules.
    # It lives in a normal category package. "codestyle" is a valid ruleset category.
    diff_filenames = <<~DOC
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/codestyle/AbstractNamingConventionRule.java
    DOC
    mock_build?(diff_filenames, nil, "#{PATH_TO_TEST_RESOURCES}/patch-ruleset.xml")

    assert(!File.exist?(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG),
           "File #{RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG} must not exist")
  end

  def test_build_all_rulesets_config
    diff_filenames = <<~DOC
      pmd-apex/src/main/java/net/sourceforge/pmd/lang/apex/rule/bestpractices/AvoidGlobalModifierRule.java
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/design/NcssCountRule.java
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/codestyle/UnnecessaryConstructorRule.java
      pmd-core/src/main/java/net/sourceforge/pmd/lang/rule/xpath/SaxonXPathRuleQuery.java
    DOC
    mock_build?(diff_filenames, nil, "#{PATH_TO_TEST_RESOURCES}/patch-ruleset.xml")

    assert(!File.exist?(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG),
           "File #{RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG} must not exist")
  end

  def test_build_all_rulesets_config_salesforce
    diff_filenames = <<~DOC
      pmd-salesforce/pmd-apex/src/main/java/net/sourceforge/pmd/lang/apex/rule/bestpractices/AvoidGlobalModifierRule.java
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/design/NcssCountRule.java
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/codestyle/UnnecessaryConstructorRule.java
      pmd-core/src/main/java/net/sourceforge/pmd/lang/rule/xpath/SaxonXPathRuleQuery.java
    DOC
    mock_build?(diff_filenames, nil, "#{PATH_TO_TEST_RESOURCES}/patch-ruleset.xml")

    assert(!File.exist?(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG),
           "File #{RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG} must not exist")
  end

  def test_filter_ruleset_single_rule
    diff_filenames = <<~DOC
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/design/NcssCountRule.java
    DOC
    mock_build?(diff_filenames, Set['java/design.xml/NcssCount'])

    expected = File.read("#{PATH_TO_TEST_RESOURCES}/expected-ncsscount.xml")
    actual = File.read(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG)
    assert_equal(expected, actual)
  end

  def test_filter_ruleset_single_rule_named_abstract
    diff_filenames = <<~DOC
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/bestpractices/AbstractClassWithoutAbstractMethodRule.java
    DOC
    mock_build?(diff_filenames, Set['java/bestpractices.xml/AbstractClassWithoutAbstractMethod'])

    expected = File.read("#{PATH_TO_TEST_RESOURCES}/expected-abstractclasswithoutabstractmethod.xml")
    actual = File.read(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG)
    assert_equal(expected, actual)
  end

  def test_filter_ruleset_single_rule_and_category
    diff_filenames = <<~DOC
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/design/NcssCountRule.java
      pmd-java/src/main/resources/category/java/codestyle.xml
    DOC
    mock_build?(diff_filenames, Set['java/design.xml/NcssCount', 'java/codestyle.xml'])

    expected = <<~DOC
      <?xml version="1.0" encoding="UTF-8"?>
      <ruleset xmlns="http://pmd.sourceforge.net/ruleset/2.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://pmd.sourceforge.net/ruleset/2.0.0 https://pmd.sourceforge.io/ruleset_2_0_0.xsd" name="Dynamic PmdTester Ruleset">
          <description>The ruleset generated by PmdTester dynamically</description>
          <rule ref="category/java/codestyle.xml"/>
          <rule ref="category/java/design.xml/NcssCount"/>
      </ruleset>
    DOC
    actual = File.read(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG)
    assert_equal(expected, actual)
  end

  def test_filter_ruleset_single_rule_and_category_duplicated
    diff_filenames = <<~DOC
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/design/NcssCountRule.java
      pmd-java/src/main/resources/category/java/design.xml
    DOC
    mock_build?(diff_filenames, Set['java/design.xml'])

    expected = <<~DOC
      <?xml version="1.0" encoding="UTF-8"?>
      <ruleset xmlns="http://pmd.sourceforge.net/ruleset/2.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://pmd.sourceforge.net/ruleset/2.0.0 https://pmd.sourceforge.io/ruleset_2_0_0.xsd" name="Dynamic PmdTester Ruleset">
          <description>The ruleset generated by PmdTester dynamically</description>
          <rule ref="category/java/design.xml"/>
      </ruleset>
    DOC
    actual = File.read(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG)
    assert_equal(expected, actual)
  end

  def test_filter_ruleset_based_on_patch_config
    options = Options.new(['--mode', 'online',
                           '--patch-config', "#{PATH_TO_TEST_RESOURCES}/patch-ruleset.xml",
                           '--patch-branch', 'test_filter_ruleset_based_on_patch_branch',
                           '--base-branch', 'main',
                           '--local-git-repo', 'target/repositories/pmd',
                           '--filter-with-patch-config',
                           '--debug'])
    RuleSetBuilder.new(options).calculate_filter_set

    assert_equal(Set['java/performance.xml/ConsecutiveLiteralAppends'], options.filter_set)
  end

  def test_build_apex_single_rule_config
    diff_filenames = <<~DOC
      pmd-apex/src/main/java/net/sourceforge/pmd/lang/apex/rule/bestpractices/AvoidGlobalModifierRule.java
    DOC
    mock_build?(diff_filenames, Set['apex/bestpractices.xml/AvoidGlobalModifier'])

    expected = <<~DOC
      <?xml version="1.0" encoding="UTF-8"?>
      <ruleset xmlns="http://pmd.sourceforge.net/ruleset/2.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://pmd.sourceforge.net/ruleset/2.0.0 https://pmd.sourceforge.io/ruleset_2_0_0.xsd" name="Dynamic PmdTester Ruleset">
          <description>The ruleset generated by PmdTester dynamically</description>
          <rule ref="category/apex/bestpractices.xml/AvoidGlobalModifier"/>
      </ruleset>
    DOC
    actual = File.read(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG)
    assert_equal(expected, actual)
  end

  def test_build_apex_single_xpath_rule_config
    diff_filenames = <<~DOC
      pmd-apex/src/main/resources/category/apex/codestyle.xml
    DOC
    mock_build?(diff_filenames, Set['apex/codestyle.xml'])

    expected = <<~DOC
      <?xml version="1.0" encoding="UTF-8"?>
      <ruleset xmlns="http://pmd.sourceforge.net/ruleset/2.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://pmd.sourceforge.net/ruleset/2.0.0 https://pmd.sourceforge.io/ruleset_2_0_0.xsd" name="Dynamic PmdTester Ruleset">
          <description>The ruleset generated by PmdTester dynamically</description>
          <rule ref="category/apex/codestyle.xml"/>
      </ruleset>
    DOC
    actual = File.read(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG)
    assert_equal(expected, actual)
  end

  def test_build_apex_single_xpath_rule_config_salesforce
    diff_filenames = <<~DOC
      pmd-salesforce/pmd-apex/src/main/resources/category/apex/codestyle.xml
    DOC
    mock_build?(diff_filenames, Set['apex/codestyle.xml'])

    expected = <<~DOC
      <?xml version="1.0" encoding="UTF-8"?>
      <ruleset xmlns="http://pmd.sourceforge.net/ruleset/2.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://pmd.sourceforge.net/ruleset/2.0.0 https://pmd.sourceforge.io/ruleset_2_0_0.xsd" name="Dynamic PmdTester Ruleset">
          <description>The ruleset generated by PmdTester dynamically</description>
          <rule ref="category/apex/codestyle.xml"/>
      </ruleset>
    DOC
    actual = File.read(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG)
    assert_equal(expected, actual)
  end

  def test_build_apex_mixed_rule_config
    diff_filenames = <<~DOC
      pmd-apex/src/main/java/net/sourceforge/pmd/lang/apex/rule/bestpractices/AvoidGlobalModifierRule.java
      pmd-apex/src/main/resources/category/apex/codestyle.xml
    DOC
    mock_build?(diff_filenames, Set['apex/bestpractices.xml/AvoidGlobalModifier', 'apex/codestyle.xml'])

    expected = <<~DOC
      <?xml version="1.0" encoding="UTF-8"?>
      <ruleset xmlns="http://pmd.sourceforge.net/ruleset/2.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://pmd.sourceforge.net/ruleset/2.0.0 https://pmd.sourceforge.io/ruleset_2_0_0.xsd" name="Dynamic PmdTester Ruleset">
          <description>The ruleset generated by PmdTester dynamically</description>
          <rule ref="category/apex/codestyle.xml"/>
          <rule ref="category/apex/bestpractices.xml/AvoidGlobalModifier"/>
      </ruleset>
    DOC
    actual = File.read(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG)
    assert_equal(expected, actual)
  end

  def test_build_apex_java_mixed_rule_config
    diff_filenames = <<~DOC
      pmd-apex/src/main/java/net/sourceforge/pmd/lang/apex/rule/bestpractices/AvoidGlobalModifierRule.java
      pmd-apex/src/main/resources/category/apex/codestyle.xml
      pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule/design/NcssCountRule.java
      pmd-java/src/main/resources/category/java/codestyle.xml
    DOC
    mock_build?(diff_filenames, Set['apex/bestpractices.xml/AvoidGlobalModifier', 'apex/codestyle.xml',
                                    'java/design.xml/NcssCount', 'java/codestyle.xml'])

    expected = <<~DOC
      <?xml version="1.0" encoding="UTF-8"?>
      <ruleset xmlns="http://pmd.sourceforge.net/ruleset/2.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://pmd.sourceforge.net/ruleset/2.0.0 https://pmd.sourceforge.io/ruleset_2_0_0.xsd" name="Dynamic PmdTester Ruleset">
          <description>The ruleset generated by PmdTester dynamically</description>
          <rule ref="category/apex/codestyle.xml"/>
          <rule ref="category/java/codestyle.xml"/>
          <rule ref="category/apex/bestpractices.xml/AvoidGlobalModifier"/>
          <rule ref="category/java/design.xml/NcssCount"/>
      </ruleset>
    DOC
    actual = File.read(RuleSetBuilder::PATH_TO_DYNAMIC_CONFIG)
    assert_equal(expected, actual)
  end

  def test_languages_based_on_patch_config
    options = Options.new(['--mode', 'online',
                           '--patch-config', "#{PATH_TO_TEST_RESOURCES}/languages.xml",
                           '--patch-branch', 'test_languages_based_on_patch_config',
                           '--base-branch', 'main',
                           '--local-git-repo', 'target/repositories/pmd',
                           '--debug'])
    langs = RuleSetBuilder.new(options).send(:determine_languages)

    assert_equal(Set['apex', 'java'], langs)
  end
end
