# frozen_string_literal: true

class OptimiaFacebookPostProperty < ApplicationRecord
  belongs_to :account

  validates :page_id, :post_id, :property_id, :source, presence: true
  validates :post_id, uniqueness: { scope: :account_id }
  validates :confidence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  def known_facts_hash
    known_facts.is_a?(Hash) ? known_facts : {}
  end
end
