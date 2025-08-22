# frozen_string_literal: true
class TagGroup < ApplicationRecord
  CHROMIUM_ADAPTER_TYPE = 'Chromium'

  include Uuid::Uuidable
  include SharedBehaviour::Named

  has_many :tags, -> { order(:map_id) } # rubocop:todo Rails/HasManyOrHasOneDependent
  belongs_to :adapter_type, class_name: 'TagGroup::AdapterType', optional: true

  scope :include_tags, -> { includes(:tags) }

  scope :visible, -> { where(visible: true) }

  scope :chromium, -> { visible.joins(:adapter_type).where(tag_group_adapter_types: { name: CHROMIUM_ADAPTER_TYPE }) }

  scope :by_adapter_type,
        ->(adapter_type_name) do
          visible.joins(:adapter_type).where(tag_group_adapter_types: { name: adapter_type_name })
        end

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def tags_sorted_by_map_id
    tags.sort_by(&:map_id)
  end

  def adapter_type_name
    adapter_type.try(:name) || TagGroup::AdapterType::UNSPECIFIED
  end

  def adapter_type_name=(name)
    self.adapter_type = TagGroup::AdapterType.find_by!(name:)
  end

  # Returns a Hash that maps from the tag index in the group to the oligo sequence for the tag
  def indexed_tags
    tags.to_h { |tag| [tag.map_id, tag.oligo] }
  end
end
