# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OptimiA connection lifecycle' do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:service) { Optimia::ChannelManager::ConnectionCenterService.new(account: account, performed_by: admin) }
  let(:adapter) { instance_double(Integrations::Optimia::ChannelManager::Providers::EvolutionAdapter) }

  before do
    account.enable_features!(:optimia_channel_manager)
    allow(Integrations::Optimia::ChannelManager::ProviderRegistry).to receive(:fetch).and_return(adapter)
    allow(Integrations::Optimia::ChannelManager::MonitorConfig).to receive(:monitoring_enabled?).and_return(true)
    allow(Integrations::Optimia::ChannelManager::Feature).to receive(:globally_enabled?).and_return(true)
    allow(Integrations::Optimia::ChannelManager::Feature).to receive(:enabled_for_account?).and_return(true)
    allow(adapter).to receive(:fetch_status!).and_return(
      Integrations::Optimia::ChannelManager::ProviderAdapter::StatusResult.new(
        remote_state: 'open',
        phone_number: '+5491112345678',
        metadata: {}
      )
    )
    allow(adapter).to receive(:disconnect!).and_return(success: true)
    allow(adapter).to receive(:delete_instance!).and_return(success: true)
    allow(adapter).to receive(:configure_chatwoot!).and_return(success: true)
  end

  def create_ready_connection
    inbox = create(:inbox, account: account, channel: create(:channel_api, account: account))
    create(
      :optimia_channel_connection,
      account: account,
      inbox: inbox,
      state: 'ready',
      lifecycle_status: 'active',
      inbox_recreation_enabled: true,
      external_instance_id: 'optimia-1-test'
    )
  end

  describe 'inbox deletion from Chatwoot settings' do
    it 'archives the connection and disables recreation' do
      connection = create_ready_connection
      inbox = connection.inbox

      inbox.destroy!

      connection.reload
      expect(connection.lifecycle_status).to eq('archived')
      expect(connection.inbox_recreation_enabled).to be(false)
      expect(connection.inbox_id).to be_nil
      expect(connection.optimia_channel_connection_audits.pluck(:action)).to include('archived_from_inbox_deletion')
    end
  end

  describe 'monitor does not recreate intentionally removed inbox' do
    it 'skips archived connections' do
      connection = create_ready_connection
      inbox = connection.inbox
      inbox.destroy!
      connection.reload

      expect do
        Optimia::ChannelManager::MonitorConnectionsJob.perform_now
      end.not_to change(Inbox, :count)

      expect(connection.reload.inbox_id).to be_nil
    end
  end

  describe 'refresh_status does not recreate archived inbox' do
    it 'returns without provisioning' do
      connection = create_ready_connection
      connection.update!(lifecycle_status: 'archived', inbox_recreation_enabled: false, inbox_id: nil)

      expect do
        service.refresh_status!(connection)
      end.not_to change(Inbox, :count)
    end
  end

  describe 'disconnect preserves inbox' do
    it 'keeps inbox and lifecycle active' do
      connection = create_ready_connection
      inbox_id = connection.inbox_id

      service.disconnect!(connection)

      connection.reload
      expect(connection.state).to eq('disconnected')
      expect(connection.lifecycle_status).to eq('active')
      expect(connection.inbox_id).to eq(inbox_id)
    end
  end

  describe Optimia::ChannelManager::DeactivateConnectionService do
    it 'prevents reconciliation' do
      connection = create_ready_connection

      described_class.new(connection: connection, performed_by: admin).perform!

      connection.reload
      expect(connection.lifecycle_status).to eq('archived')
      expect(connection.inbox_recreation_enabled).to be(false)
    end
  end

  describe Optimia::ChannelManager::RestoreConnectionService do
    it 'restores archived connection' do
      connection = create_ready_connection
      connection.update!(lifecycle_status: 'archived', inbox_recreation_enabled: false)

      described_class.new(connection: connection, performed_by: admin).perform!

      connection.reload
      expect(connection.lifecycle_status).to eq('active')
      expect(connection.inbox_recreation_enabled).to be(true)
    end
  end

  describe Optimia::ChannelManager::DeleteConnectionService do
    it 'is idempotent' do
      connection = create_ready_connection

      described_class.new(connection: connection, performed_by: admin, delete_inbox: false).perform!
      expect(connection.reload.lifecycle_status).to eq('deleted')

      expect do
        described_class.new(connection: connection, performed_by: admin).perform!
      end.not_to raise_error
    end

    it 'tolerates unreachable Evolution' do
      connection = create_ready_connection
      allow(adapter).to receive(:disconnect!).and_raise(StandardError, 'upstream down')
      allow(adapter).to receive(:delete_instance!).and_raise(StandardError, 'upstream down')

      described_class.new(connection: connection, performed_by: admin, delete_inbox: false).perform!

      expect(connection.reload.lifecycle_status).to eq('deleted')
    end

    it 'tolerates missing webhook' do
      connection = create_ready_connection
      connection.inbox.channel.update!(webhook_url: nil)

      described_class.new(connection: connection, performed_by: admin, delete_inbox: false).perform!

      expect(connection.reload.lifecycle_status).to eq('deleted')
    end
  end

  describe 'race between monitor and deletion' do
    it 'does not recreate inbox while deleting' do
      connection = create_ready_connection
      connection.update!(lifecycle_status: 'deleting', inbox_recreation_enabled: false, inbox_id: nil)

      expect(Optimia::ChannelManager::ProvisioningService.new(connection: connection, performed_by: admin).perform!).to be_nil
      expect do
        Optimia::ChannelManager::MonitorConnectionsJob.perform_now
      end.not_to change(Inbox, :count)
    end
  end

  describe 'non-OptimiA API inbox' do
    it 'is unaffected' do
      inbox = create(:inbox, account: account, channel: create(:channel_api, account: account))

      expect { inbox.destroy! }.not_to raise_error
      expect(OptimiaChannelConnection.find_by(inbox_id: inbox.id)).to be_nil
    end
  end

  describe 'deleted records are never recreated' do
    it 'blocks provisioning' do
      connection = create_ready_connection
      connection.update!(lifecycle_status: 'deleted', inbox_recreation_enabled: false, inbox_id: nil)

      result = Optimia::ChannelManager::ProvisioningService.new(connection: connection, performed_by: admin).perform!
      expect(result).to be_nil
    end
  end

  describe 'active accidental loss with auto repair' do
    it 'can repair when enabled' do
      connection = create_ready_connection
      connection.update!(inbox_id: nil)

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('OPTIMIA_AUTO_REPAIR_MISSING_INBOX', anything).and_return('true')

      expect do
        Optimia::ChannelManager::MissingInboxHandler.new(connection: connection, performed_by: admin).perform!
      end.to change(Inbox, :count).by(1)
    end
  end

  describe 'audit logging' do
    it 'records deactivation' do
      connection = create_ready_connection

      Optimia::ChannelManager::DeactivateConnectionService.new(connection: connection, performed_by: admin).perform!

      expect(connection.optimia_channel_connection_audits.pluck(:action)).to include('archived')
    end
  end
end
