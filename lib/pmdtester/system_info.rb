# frozen_string_literal: true

module PmdTester
  # Utility to deal with semantic versions
  class SystemInfo
    def physical_memory
      meminfo = File.read('/proc/meminfo')
      mem_total_line = meminfo.lines.find { |line| line.start_with?('MemTotal:') }
      mem_total_kb = mem_total_line.split[1].to_i # Get the value in kB
      mem_total_gb = mem_total_kb / 1024.0 / 1024.0 # Convert kB to GB
      mem_total_gb = mem_total_gb.round(1)
      "#{mem_total_gb} GB"
    end

    def uname
      info = Etc.uname
      "#{info[:sysname]} #{info[:release]}"
    end

    def cpu_info
      cpuinfo = File.read('/proc/cpuinfo')
      cpus = parse_cpuinfo(cpuinfo)
      model_name = cpus.map { |cpu| cpu[:model_name] }.uniq.join(', ')
      sockets = cpus.map { |cpu| cpu[:physical_id] }.uniq.count
      cores = cpus.map { |cpu| cpu[:core_id] }.uniq.count
      threads = cpus.count

      "#{model_name} (sockets: #{sockets}, cores: #{cores}, hardware threads: #{threads})"
    end

    private

    def parse_cpuinfo(cpuinfo)
      cpus = []
      cpu_index = -1

      cpuinfo.lines.each do |line|
        if line.start_with?('processor')
          cpu_index = line.split(':')[1].strip.to_i
          cpus[cpu_index] = {}
        end
        if line.start_with?('model name')
          model_name = line.split(':')[1].strip
          cpus[cpu_index][:model_name] = model_name
        end
        if line.start_with?('physical id')
          physical_id = line.split(':')[1].strip.to_i
          cpus[cpu_index][:physical_id] = physical_id
        end
        if line.start_with?('core id')
          core_id = line.split(':')[1].strip.to_i
          cpus[cpu_index][:core_id] = core_id
        end
      end
      cpus
    end
  end
end
