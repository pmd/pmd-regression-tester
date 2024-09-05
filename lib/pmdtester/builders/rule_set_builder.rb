# frozen_string_literal: true

require 'nokogiri'
require 'set'

module PmdTester
  # This class is responsible for generation dynamic configuration
  # according to the difference between base and patch branch of Pmd.
  # Attention: we only consider java rulesets now.
  class RuleSetBuilder
    include PmdTester
    PATH_TO_DYNAMIC_CONFIG = 'target/dynamic-config.xml'
    NO_RULES_CHANGED_MESSAGE = 'No regression tested rules have been changed!'

    def initialize(options)
      @options = options
    end

    #
    # Creates a dynamic ruleset based on the changed sources.
    # Returns true, when rules are affected by the changed sources.
    # Returns false, when no rules are affected and regression tester can be skipped.
    #
    def build?
      languages = determine_languages
      filenames = diff_filenames(languages)
      run_required, rule_refs = get_rule_refs(filenames)
      if run_required
        output_filter_set(rule_refs)
        build_config_file(rule_refs)
        logger.debug "Dynamic configuration: #{[rule_refs]}"
      else
        logger.info NO_RULES_CHANGED_MESSAGE
      end
      run_required
    end

    def calculate_filter_set
      output_filter_set([])
    end

    def output_filter_set(rule_refs)
      if rule_refs.empty?
        if @options.mode == Options::ONLINE && @options.filter_with_patch_config
          @options.filter_set = Set[]
          doc = File.open(@options.patch_config) { |f| Nokogiri::XML(f) }
          rules = doc.css('ruleset rule')
          rules.each do |r|
            ref = r.attributes['ref'].content
            ref.delete_prefix!('category/')
            @options.filter_set.add(ref)
          end

          logger.info "Using filter based on patch config #{@options.patch_config}: " \
                      "#{@options.filter_set}"
        else
          # if `rule_refs` is empty, then no filter can be used when comparing to the baseline
          logger.info 'No filter when comparing patch to baseline'
          @options.filter_set = nil
        end
      else
        logger.info "Filter is now #{rule_refs}"
        @options.filter_set = rule_refs
      end
    end

    #
    # Determines the rules or category rulesets, that are potentially affected by the change.
    # Returns an empty set, if all rules are affected and there is no
    # filtering possible or if no rules are affected.
    # Whether to run the regression test is returned as an additional boolean flag.
    #
    def get_rule_refs(filenames)
      run_required, categories, rules = determine_categories_rules(filenames)
      logger.debug "Regression test required: #{run_required}"
      logger.debug "Categories: #{categories}"
      logger.debug "Rules: #{rules}"

      # filter out all individual rules that are already covered by a complete category
      categories.each do |cat|
        rules.delete_if { |e| e.start_with?(cat) }
      end

      refs = Set[]
      refs.merge(categories)
      refs.merge(rules)
      [run_required, refs]
    end

    def build_config_file(rule_refs)
      if rule_refs.empty?
        logger.debug 'All rules are used. Not generating a dynamic ruleset.'
        logger.debug "Using the configured/default ruleset base_config=#{@options.base_config} " \
                     "patch_config=#{@options.patch_config}"
        return
      end

      write_dynamic_file(rule_refs)
    end

    def write_dynamic_file(rule_refs)
      logger.debug "Generating dynamic configuration for: #{[rule_refs]}"
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.ruleset('xmlns' => 'http://pmd.sourceforge.net/ruleset/2.0.0',
                    'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                    'xsi:schemaLocation' => 'http://pmd.sourceforge.net/ruleset/2.0.0 https://pmd.sourceforge.io/ruleset_2_0_0.xsd',
                    'name' => 'Dynamic PmdTester Ruleset') do
          xml.description 'The ruleset generated by PmdTester dynamically'
          rule_refs.each do |entry|
            xml.rule('ref' => "category/#{entry}")
          end
        end
      end
      doc = builder.to_xml(indent: 4, encoding: 'UTF-8')
      File.open(PATH_TO_DYNAMIC_CONFIG, 'w') do |x|
        x << doc.gsub(/\n\s+\n/, "\n")
      end
      @options.base_config = PATH_TO_DYNAMIC_CONFIG
      @options.patch_config = PATH_TO_DYNAMIC_CONFIG
    end

    private

    def determine_categories_rules(filenames)
      regression_test_required = false
      categories = Set[]
      rules = Set[]
      filenames.each do |filename|
        matched = check_single_filename(filename, categories, rules)
        regression_test_required = true if matched

        next if matched

        logger.info "Change in file #{filename} doesn't match specific rule/category - enable all rules"
        regression_test_required = true
        categories.clear
        rules.clear
        break
      end
      [regression_test_required, categories, rules]
    end

    def check_single_filename(filename, categories, rules)
      logger.debug "Checking #{filename}"

      # matches Java-based rule implementations
      match_data = %r{.+/src/main/java/.+/lang/([^/]+)/rule/([^/]+)/([^/]+)Rule.java}.match(filename)
      unless match_data.nil?
        logger.debug "Matches: #{match_data.inspect}"
        rules.add("#{match_data[1]}/#{match_data[2]}.xml/#{match_data[3]}")
        return true
      end

      # matches xpath rules
      match_data = %r{.+/src/main/resources/category/([^/]+)/([^/]+).xml}.match(filename)
      unless match_data.nil?
        logger.debug "Matches: #{match_data.inspect}"
        categories.add("#{match_data[1]}/#{match_data[2]}.xml")
        return true
      end

      false
    end

    def diff_filenames(languages)
      filenames = nil
      Dir.chdir(@options.local_git_repo) do
        base = @options.base_branch
        patch = @options.patch_branch

        filepath_filter = ''
        unless languages.empty?
          filepath_filter = '-- pmd-core/src/main'
          languages.each { |l| filepath_filter = "#{filepath_filter} pmd-#{l}/src/main" }
        end

        # We only need to support git here, since PMD's repo is using git.
        diff_cmd = "git diff --name-only #{base}..#{patch} #{filepath_filter}"
        filenames = Cmd.execute_successfully(diff_cmd)
      end
      filenames.split("\n")
    end

    #
    # Determines all languages, that are part of the regression test.
    # This is based on the configured rules/rulesets.
    #
    def determine_languages
      languages = Set[]
      doc = File.open(@options.patch_config) { |f| Nokogiri::XML(f) }
      rules = doc.css('ruleset rule')
      rules.each do |r|
        ref = r.attributes['ref'].content
        languages.add(ref.split('/')[1])
      end
      languages
    end
  end
end
