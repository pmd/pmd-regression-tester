# frozen_string_literal: true

require 'rufus-scheduler'

module PmdTester
  # Helper class that provides a simple progress logging
  class SimpleProgressLogger
    include PmdTester

    def initialize(task_name)
      @task_name = task_name
    end

    def start
      logger.info "Starting #{@task_name}"
      message_counter = 1
      @scheduler = Rufus::Scheduler.new
      @scheduler.every '2m' do
        logger.info "Still #{@task_name} (#{message_counter})..."
        message_counter += 1
      end
    end

    def stop
      @scheduler.shutdown
    end
  end
end
