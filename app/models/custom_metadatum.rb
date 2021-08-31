# frozen_string_literal: true
class CustomMetadatum < ApplicationRecord # rubocop:todo Style/Documentation
  belongs_to :custom_metadatum_collection

  validates :value, presence: true
  validates :key, uniqueness: { scope: :custom_metadatum_collection_id, case_sensitive: false }

  def to_h
    { key => value }
  end
end
