class TagGroup < ApplicationRecord
  CHROMIUM_ADAPTER_TYPE = 'Chromium'.freeze

  include Uuid::Uuidable

  has_many :tags, ->() { order('map_id ASC') }
  belongs_to :adapter_type, class_name: 'TagGroup::AdapterType', optional: true

  scope :include_tags, ->() { includes(:tags) }

  scope :visible, -> { where(visible: true) }

  scope :chromium, -> { visible.joins(:adapter_type).where(tag_group_adapter_types: { name: CHROMIUM_ADAPTER_TYPE }) }

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def tags_sorted_by_map_id
    tags.sort_by(&:map_id)
  end

  def adapter_type_name
    adapter_type.try(:name) || TagGroup::AdapterType::UNSPECIFIED
  end

  # Returns a Hash that maps from the tag index in the group to the oligo sequence for the tag
  def indexed_tags
    Hash[tags.map { |tag| [tag.map_id, tag.oligo] }]
  end
end
