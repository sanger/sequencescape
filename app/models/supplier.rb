# frozen_string_literal: true
class Supplier < ApplicationRecord
  include Uuid::Uuidable
  # include ::Io::Supplier::ApiIoSupport
  include SampleManifest::Associations
  include SharedBehaviour::Named

  has_many :studies, -> { distinct }, through: :sample_manifests
  validates :name, presence: true

  # Named scope for search by query string behaviour
  scope :for_search_query,
        ->(query) do
          where(['suppliers.name IS NOT NULL AND (suppliers.name LIKE :like)', { like: "%#{query}%", query: query }])
        end
end
