# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::JfrSummary
class TestJfrSummary < Test::Unit::TestCase
  include PmdTester

  def test_load
    PmdTester::Cmd.stubs(:execute_successfully).with('jfr print --json --events jdk.JVMInformation path/recording.jfr')
                  .returns(File.read('test/resources/jfr_summary/jvm_information.json'))
                  .once
    PmdTester::Cmd.stubs(:execute_successfully).with('jfr print --json --events jdk.Shutdown path/recording.jfr')
                  .returns(File.read('test/resources/jfr_summary/shutdown.json'))
                  .once
    PmdTester::Cmd.stubs(:execute_successfully).with('jfr print --json --events jdk.GCHeapSummary path/recording.jfr')
                  .returns(File.read('test/resources/jfr_summary/gc_heap_summary.json'))
                  .once
    PmdTester::Cmd.stubs(:execute_successfully).with('jfr print --json --events jdk.CPULoad path/recording.jfr')
                  .returns(File.read('test/resources/jfr_summary/cpu_load.json'))
                  .once

    jfr_summary = JfrSummary.new
    jfr_summary.load('path/recording.jfr')

    assert_in_delta(5.1, jfr_summary.execution_time, 0.1)
    assert_equal(196_134_808, jfr_summary.max_heap_memory)
    assert_in_delta(0.6361323, jfr_summary.max_cpu_load, 0.001)
    assert_in_delta(0.38991377499999996, jfr_summary.avg_cpu_load, 0.001)
  end

  def test_load_empty
    PmdTester::Cmd.stubs(:execute_successfully).with('jfr print --json --events jdk.JVMInformation path/recording.jfr')
                  .returns('{"recording":{"events":[]}}')
                  .once
    PmdTester::Cmd.stubs(:execute_successfully).with('jfr print --json --events jdk.Shutdown path/recording.jfr')
                  .returns('{"recording":{"events":[]}}')
                  .once
    PmdTester::Cmd.stubs(:execute_successfully).with('jfr print --json --events jdk.GCHeapSummary path/recording.jfr')
                  .returns('{"recording":{"events":[]}}')
                  .once
    PmdTester::Cmd.stubs(:execute_successfully).with('jfr print --json --events jdk.CPULoad path/recording.jfr')
                  .returns('{"recording":{"events":[]}}')
                  .once

    jfr_summary = JfrSummary.new
    jfr_summary.load('path/recording.jfr')

    assert_in_delta(0.0, jfr_summary.execution_time, 0.1)
    assert_equal(0, jfr_summary.max_heap_memory)
    assert_in_delta(0.0, jfr_summary.max_cpu_load, 0.001)
    assert_in_delta(0.0, jfr_summary.avg_cpu_load, 0.001)
  end
end
