# frozen_string_literal: true

module PmdTester
  # Utility to deal with semantic versions
  class Semver
    def self.compare(version_a, version_b)
      result = internal_compare(version_a, version_b)
      PmdTester.logger.debug "  result: #{result}"
      result
    end

    private_class_method def self.internal_compare(version_a, version_b)
      PmdTester.logger.debug "Comparing #{version_a} <=> #{version_b}"
      m = /(\d+)\.(\d+)\.(\d+)(.*)/.match(version_a)
      a_major = m[1].to_i
      a_minor = m[2].to_i
      a_patch = m[3].to_i
      a_snapshot = m[4]
      PmdTester.logger.debug "  a_major: #{a_major} a_minor: #{a_minor} a_patch: #{a_patch} a_snapshot: #{a_snapshot}"

      m = /(\d+)\.(\d+)\.(\d+)(.*)/.match(version_b)
      b_major = m[1].to_i
      b_minor = m[2].to_i
      b_patch = m[3].to_i
      b_snapshot = m[4]
      PmdTester.logger.debug "  b_major: #{b_major} b_minor: #{b_minor} b_patch: #{b_patch} b_snapshot: #{b_snapshot}"

      return a_major <=> b_major if a_major != b_major
      return a_minor <=> b_minor if a_minor != b_minor
      return a_patch <=> b_patch if a_patch != b_patch

      compare_snapshots(a_snapshot, b_snapshot)
    end

    private_class_method def self.compare_snapshots(a_snapshot, b_snapshot)
      return -1 if a_snapshot == '-SNAPSHOT' && b_snapshot == ''
      return 1 if a_snapshot == '' && b_snapshot == '-SNAPSHOT'

      a_snapshot <=> b_snapshot
    end
  end
end
