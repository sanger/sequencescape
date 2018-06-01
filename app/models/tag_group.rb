
class TagGroup < ApplicationRecord
  include Uuid::Uuidable

  has_many :tags, ->() { order('map_id ASC') }

  scope :include_tags, ->() { includes(:tags) }

  scope :visible, -> { where(visible: true) }

  validates_presence_of :name
  validates_uniqueness_of :name

  def tags_sorted_by_map_id
    tags.sort_by(&:map_id)
  end

  # Returns a Hash that maps from the tag index in the group to the oligo sequence for the tag
  def indexed_tags
    Hash[tags.map { |tag| [tag.map_id, tag.oligo] }]
  end
end
