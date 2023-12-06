# frozen_string_literal: true

# A polymetadatum can be assigned to any metadatable record.
class PolyMetadatum < ApplicationRecord
  # Associations
  belongs_to :metadatable, polymorphic: true, optional: false
  has_many :poly_metadata, as: :metadatable, dependent: :destroy

  # Validations
  validates :key, presence: true # otherwise nil is a valid key
  validates :value, presence: true
  validates :key, uniqueness: { scope: :metadatable_id, case_sensitive: false }

  # Methods
  def to_h
    { key => value }
  end
end
