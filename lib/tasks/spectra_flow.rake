# frozen_string_literal: true

namespace :spectra_flow do
  desc 'Run Spectra Flow health check for an account (safe output, no secrets)'
  task :health_check, [:account_id] => :environment do |_task, args|
    account = Account.find(args[:account_id] || 1)
    result = Integrations::SpectraFlow::DocumentsService.new(account: account).health_check
    puts JSON.pretty_generate(result.as_json)
  end
end
