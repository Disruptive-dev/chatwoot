# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::FacebookComments::IntentClassifier do
  {
    'Precio?' => :price,
    'Me interesa' => :interest,
    'Info' => :info,
    'Ubicación?' => :location,
    'Sigue disponible?' => :availability,
    'Quiero visitarla' => :visit,
    'Quiero hablar con un asesor' => :handoff,
    '👍' => :reaction,
    '   ' => :irrelevant
  }.each do |message, expected_intent|
    it "classifies '#{message}' as #{expected_intent}" do
      expect(described_class.new(message).classify).to eq(expected_intent)
    end
  end
end
