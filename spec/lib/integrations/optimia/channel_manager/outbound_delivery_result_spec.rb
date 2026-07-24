# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::Optimia::ChannelManager::OutboundDeliveryResult do
  describe '.extract_remote_id' do
    it 'extracts messageId' do
      expect(described_class.extract_remote_id({ 'messageId' => 'MSG-1' })).to eq('MSG-1')
    end

    it 'extracts key.id' do
      expect(described_class.extract_remote_id({ 'key' => { 'id' => 'WA-KEY-1' } })).to eq('WA-KEY-1')
    end

    it 'extracts nested data.key.id variant' do
      body = { 'data' => { 'key' => { 'id' => 'NESTED-1' } } }
      expect(described_class.extract_remote_id(body)).to eq('NESTED-1')
    end

    it 'returns nil for bot acknowledgement payloads' do
      expect(described_class.extract_remote_id({ 'message' => 'bot' })).to be_nil
    end
  end
end
