# frozen_string_literal: true

require 'timeout'

module Optimia
  module TechnicalHealth
    module Checkers
      class StorageChecker < BaseChecker
        private

        def perform_check
          disk = disk_usage
          db_size_mb = database_size_mb
          used_percent = disk[:used_percent]

          if used_percent.nil?
            return {
              status: 'unknown',
              version: nil,
              uptime_seconds: nil,
              error_count: 0,
              metadata: {
                disk_used_percent: nil,
                disk_available_gb: disk[:available_gb],
                database_size_mb: db_size_mb
              }
            }
          end

          status = used_percent >= 90 ? 'critical' : used_percent >= 75 ? 'degraded' : 'healthy'

          {
            status: status,
            version: nil,
            uptime_seconds: nil,
            error_count: status == 'healthy' ? 0 : 1,
            metadata: {
              disk_used_percent: used_percent,
              disk_available_gb: disk[:available_gb],
              database_size_mb: db_size_mb
            }
          }
        end

        def disk_usage
          return { used_percent: nil, available_gb: nil } if Rails.env.test?

          output = nil
          Timeout.timeout(5) do
            output = `df -P / 2>/dev/null | tail -1`.strip
          end
          return { used_percent: nil, available_gb: nil } if output.blank?

          parts = output.split
          {
            used_percent: parts[4].to_s.delete('%').to_i,
            available_gb: (parts[3].to_i / 1024.0 / 1024.0).round(2)
          }
        rescue Timeout::Error
          { used_percent: nil, available_gb: nil }
        end

        def database_size_mb
          sql = 'SELECT pg_database_size(current_database()) / 1024.0 / 1024.0 AS size_mb'
          ActiveRecord::Base.connection.select_value(sql)&.to_f&.round(2)
        end
      end
    end
  end
end
