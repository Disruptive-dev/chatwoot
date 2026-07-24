# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    module Checkers
      class WhatsappChecker < BaseChecker
        private

        def perform_check
          connections = OptimiaChannelConnection.lifecycle_active.to_a
          operational = connections.count { |c| %w[ready connected syncing].include?(c.state) }
          with_qr = connections.count { |c| %w[waiting_qr waiting_scan qr_required].include?(c.state) }
          with_error = connections.count { |c| %w[failed error degraded].include?(c.state) }
          archived = OptimiaChannelConnection.where(lifecycle_status: 'archived').count

          status = 'healthy'
          status = 'critical' if with_error.positive? && operational.zero? && connections.any?
          status = 'degraded' if status == 'healthy' && (with_error.positive? || with_qr.positive?)

          {
            status: status,
            version: nil,
            uptime_seconds: nil,
            error_count: with_error,
            metadata: {
              total_connections: connections.size,
              operational: operational,
              with_qr: with_qr,
              with_error: with_error,
              archived: archived
            }
          }
        end
      end
    end
  end
end
