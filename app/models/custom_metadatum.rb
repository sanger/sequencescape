class CustomMetadatum < ApplicationRecord
  belongs_to :custom_metadatum_collection

  validates_presence_of :value
  validates_uniqueness_of :key, scope: :custom_metadatum_collection_id

  def to_h
    { key => value }
  end
end
