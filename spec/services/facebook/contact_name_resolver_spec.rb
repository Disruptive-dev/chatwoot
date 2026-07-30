# frozen_string_literal: true

require 'rails_helper'

describe Facebook::ContactNameResolver do
  describe '.resolve' do
    it 'returns the full name when Meta provides first and last name' do
      expect(described_class.resolve('first_name' => 'Jane', 'last_name' => 'Doe')).to eq('Jane Doe')
    end

    it 'returns name when Meta provides only name' do
      expect(described_class.resolve('name' => 'Jane Doe')).to eq('Jane Doe')
    end

    it 'returns first_name when only first_name is present' do
      expect(described_class.resolve('first_name' => 'Jane')).to eq('Jane')
    end

    it 'returns Facebook User when Meta returns nil values' do
      expect(described_class.resolve('first_name' => nil, 'last_name' => nil, 'name' => nil)).to eq('Facebook User')
    end

    it 'returns Facebook User when Meta returns empty strings' do
      expect(described_class.resolve('first_name' => '', 'last_name' => '', 'name' => '')).to eq('Facebook User')
    end

    it 'returns Facebook User when Meta returns whitespace-only values' do
      expect(described_class.resolve('first_name' => '   ', 'last_name' => ' ', 'name' => "\t")).to eq('Facebook User')
    end

    it 'strips surrounding whitespace from valid names' do
      expect(described_class.resolve('first_name' => ' Jane ', 'last_name' => ' Doe ')).to eq('Jane Doe')
    end
  end

  describe '.legacy_fallback?' do
    it 'detects John Doe as legacy fallback' do
      expect(described_class.legacy_fallback?('John Doe')).to be(true)
    end

    it 'does not treat real names as legacy fallback' do
      expect(described_class.legacy_fallback?('Jane Doe')).to be(false)
    end
  end

  describe '.refreshable_fallback?' do
    it 'allows refreshing John Doe and Facebook User contacts' do
      expect(described_class.refreshable_fallback?('John Doe')).to be(true)
      expect(described_class.refreshable_fallback?('Facebook User')).to be(true)
    end

    it 'does not refresh contacts with real names' do
      expect(described_class.refreshable_fallback?('Jane Doe')).to be(false)
    end
  end
end
