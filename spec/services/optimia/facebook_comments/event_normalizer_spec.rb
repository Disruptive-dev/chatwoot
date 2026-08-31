# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::FacebookComments::EventNormalizer do
  subject(:events) { described_class.new(payload).normalize_all }

  let(:payload) do
    {
      object: 'page',
      entry: [
        {
          id: 'page_123',
          changes: [
            {
              field: 'feed',
              value: {
                item: 'comment',
                verb: 'add',
                comment_id: 'c_1',
                post_id: 'page_123_post_1',
                from: { id: 'user_1', name: 'Test User' },
                message: 'Precio?',
                created_time: 1_700_000_000
              }
            }
          ]
        }
      ]
    }
  end

  it 'normalizes comment add events' do
    expect(events.size).to eq(1)
    expect(events.first).to include(
      page_id: 'page_123',
      comment_id: 'c_1',
      post_id: 'page_123_post_1',
      message: 'Precio?',
      event_type: 'comment_add'
    )
  end
end
