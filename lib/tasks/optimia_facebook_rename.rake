# frozen_string_literal: true

namespace :optimia do
  namespace :facebook do
    desc 'Rename legacy Facebook Messenger fallback contacts (dry-run by default; pass false to apply)'
    task :rename_legacy_fallback_contacts, [:dry_run] => :environment do |_task, args|
      dry_run = args[:dry_run] != 'false'
      legacy_name = Facebook::ContactNameResolver::LEGACY_FALLBACK_CONTACT_NAME
      target_name = Facebook::ContactNameResolver::DEFAULT_FACEBOOK_CONTACT_NAME

      scope = Contact.joins(contact_inboxes: :inbox)
                     .where(name: legacy_name, inboxes: { channel_type: 'Channel::FacebookPage' })
                     .distinct

      count = scope.count
      puts({ task: 'optimia:facebook:rename_legacy_fallback_contacts', dry_run: dry_run, affected_contacts: count }.to_json)

      next if dry_run

      updated = 0
      scope.find_each do |contact|
        contact.update!(name: target_name)
        updated += 1
        puts({ contact_id: contact.id, account_id: contact.account_id, from: legacy_name, to: target_name }.to_json)
      end

      puts({ updated_contacts: updated }.to_json)
    end
  end
end
