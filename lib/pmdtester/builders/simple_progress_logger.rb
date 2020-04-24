# frozen_string_literal: true

require 'rufus-scheduler'

module PmdTester
  # Helper class that provides a simple progress logging
  class SimpleProgressLogger
    include PmdTester
    def initialize(project_name)
      @project_name = project_name
    end

    def start
      logger.info "Starting to generate #{@project_name}'s PMD report"
      message_counter = 1
      @scheduler = Rufus::Scheduler.new
      @scheduler.every '2m' do
        logger.info "Still generating #{@project_name}'s PMD report (#{message_counter})..."
        message_counter += 1
      end
    end

    def stop
      @scheduler.shutdown
    end
  end
end
