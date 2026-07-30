# frozen_string_literal: true

namespace :optimia do
  namespace :facebook do
    desc 'Diagnose Facebook Messenger channel for an inbox (read-only, no secrets printed)'
    task :diagnose, %i[inbox_id psid] => :environment do |_task, args|
      inbox = Inbox.find(args[:inbox_id])
      result = Facebook::DiagnosticService.new(inbox: inbox, psid: args[:psid]).perform
      puts result.to_json
      exit(result[:channel_present] ? 0 : 1)
    rescue ActiveRecord::RecordNotFound
      puts({ error: 'inbox_not_found', inbox_id: args[:inbox_id] }.to_json)
      exit 1
    rescue ArgumentError => e
      puts({ error: e.message }.to_json)
      exit 1
    end
  end
end
