# DO NOT EDIT THIS FILE. Instead, edit Rakefile, and run `rake hoe:spec`.

# -*- encoding: utf-8 -*-
# stub: pmdtester 1.0.0.pre.SNAPSHOT ruby lib

Gem::Specification.new do |s|
  s.name = "pmdtester".freeze
  s.version = "1.0.0.pre.SNAPSHOT"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andreas Dangel".freeze, "Binguo Bao".freeze]
  s.date = "2018-10-08"
  s.description = "A regression testing tool ensure that new problems and unexpected behaviors will not be introduced to PMD project after fixing an issue , and new rules can work as expected.".freeze
  s.email = ["andreas.dangel@adangel.org".freeze, "djydewang@gmail.com".freeze]
  s.executables = ["pmdtester".freeze]
  s.extra_rdoc_files = ["History.md".freeze, "Manifest.txt".freeze, "README.rdoc".freeze]
  s.files = [".hoerc".freeze, ".rubocop.yml".freeze, ".rubocop_todo.yml".freeze, ".travis.yml".freeze, "Gemfile".freeze, "History.md".freeze, "LICENSE".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "Rakefile".freeze, "bin/pmdtester".freeze, "config/all-java.xml".freeze, "config/design.xml".freeze, "config/project-list.xml".freeze, "config/projectlist_1_0_0.xsd".freeze, "lib/pmdtester.rb".freeze, "lib/pmdtester/builders/diff_builder.rb".freeze, "lib/pmdtester/builders/diff_report_builder.rb".freeze, "lib/pmdtester/builders/html_report_builder.rb".freeze, "lib/pmdtester/builders/pmd_report_builder.rb".freeze, "lib/pmdtester/builders/rule_set_builder.rb".freeze, "lib/pmdtester/builders/summary_report_builder.rb".freeze, "lib/pmdtester/cmd.rb".freeze, "lib/pmdtester/parsers/options.rb".freeze, "lib/pmdtester/parsers/pmd_report_document.rb".freeze, "lib/pmdtester/parsers/projects_parser.rb".freeze, "lib/pmdtester/pmd_branch_detail.rb".freeze, "lib/pmdtester/pmd_error.rb".freeze, "lib/pmdtester/pmd_report_detail.rb".freeze, "lib/pmdtester/pmd_violation.rb".freeze, "lib/pmdtester/project.rb".freeze, "lib/pmdtester/report_diff.rb".freeze, "lib/pmdtester/resource_locator.rb".freeze, "lib/pmdtester/runner.rb".freeze, "pmdtester.gemspec".freeze, "resources/css/maven-base.css".freeze, "resources/css/maven-theme.css".freeze]
  s.homepage = "https://github.com/pmd/pmd-regression-tester".freeze
  s.licenses = ["BSD-2-Clause".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0".freeze)
  s.rubygems_version = "2.7.7".freeze
  s.summary = "A regression testing tool ensure that new problems and unexpected behaviors will not be introduced to PMD project after fixing an issue , and new rules can work as expected.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.8.2"])
      s.add_runtime_dependency(%q<slop>.freeze, ["~> 4.6.2"])
      s.add_development_dependency(%q<hoe-bundler>.freeze, ["~> 1.2"])
      s.add_development_dependency(%q<hoe-git>.freeze, ["~> 1.6"])
      s.add_development_dependency(%q<minitest>.freeze, ["~> 5.10.1"])
      s.add_development_dependency(%q<mocha>.freeze, ["~> 1.5.0"])
      s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.51.0"])
      s.add_development_dependency(%q<test-unit>.freeze, ["~> 3.2.3"])
      s.add_development_dependency(%q<rdoc>.freeze, ["< 7", ">= 4.0"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.17"])
    else
      s.add_dependency(%q<nokogiri>.freeze, ["~> 1.8.2"])
      s.add_dependency(%q<slop>.freeze, ["~> 4.6.2"])
      s.add_dependency(%q<hoe-bundler>.freeze, ["~> 1.2"])
      s.add_dependency(%q<hoe-git>.freeze, ["~> 1.6"])
      s.add_dependency(%q<minitest>.freeze, ["~> 5.10.1"])
      s.add_dependency(%q<mocha>.freeze, ["~> 1.5.0"])
      s.add_dependency(%q<rubocop>.freeze, ["~> 0.51.0"])
      s.add_dependency(%q<test-unit>.freeze, ["~> 3.2.3"])
      s.add_dependency(%q<rdoc>.freeze, ["< 7", ">= 4.0"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.17"])
    end
  else
    s.add_dependency(%q<nokogiri>.freeze, ["~> 1.8.2"])
    s.add_dependency(%q<slop>.freeze, ["~> 4.6.2"])
    s.add_dependency(%q<hoe-bundler>.freeze, ["~> 1.2"])
    s.add_dependency(%q<hoe-git>.freeze, ["~> 1.6"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.10.1"])
    s.add_dependency(%q<mocha>.freeze, ["~> 1.5.0"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.51.0"])
    s.add_dependency(%q<test-unit>.freeze, ["~> 3.2.3"])
    s.add_dependency(%q<rdoc>.freeze, ["< 7", ">= 4.0"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.17"])
  end
end

# DO NOT EDIT THIS FILE. Instead, edit Rakefile, and run `rake hoe:spec`.
