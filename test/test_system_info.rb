# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::SystemInfo
class TestSystemInfo < Test::Unit::TestCase
  include TestUtils

  def test_physical_memory
    File.stubs(:read).with('/proc/meminfo').returns(
      "MemTotal:       33030144 kB\n" \
      "MemFree:        16621564 kB\n" \
      "SwapTotal:      16621564 kB\n" \
      "SwapFree:       16621564 kB\n"
    )
    system_info = PmdTester::SystemInfo.new
    assert_equal('31.5 GB', system_info.physical_memory)
  end

  def test_uname
    Etc.stubs(:uname).returns({ sysname: 'Foo', release: '1.0' })
    uname = PmdTester::SystemInfo.new.uname
    assert_equal('Foo 1.0', uname)
  end

  def test_cpu_info
    cpuinfo_fixture = File.read('test/resources/system_info/cpuinfo.txt')
    File.stubs(:read).with('/proc/cpuinfo').returns(cpuinfo_fixture)
    system_info = PmdTester::SystemInfo.new
    cpu_info = system_info.cpu_info
    assert_equal('Vendor Model 123 @ 1GHz (sockets: 1, cores: 2, hardware threads: 4)', cpu_info)
  end
end
