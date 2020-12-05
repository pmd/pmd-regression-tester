# frozen_string_literal: true

module PmdTester
  # This class is responsible for locating the static resources of PmdTester.
  class ResourceLocator
    def self.locate(resource_path)
      File.expand_path(File.dirname(__FILE__) + "/../../#{resource_path}")
    end

    def self.resource(resource_path)
      locate("resources/#{resource_path}")
    end
  end
end
