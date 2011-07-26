class TagGroup < ActiveRecord::Base
  has_many :tags
  acts_as_audited :on => [:destroy, :update]

  validates_presence_of :name

  def create_tags(tags_properties)
    return if tags_properties.blank?
    tags_properties.each do |index,tag_properties|
      next if tag_properties[:oligo].blank?
      self.tags << Tag.create(tag_properties)
    end
  end

  def tags_sorted_by_map_id
    self.tags.sort_by(&:map_id)
  end

  # Returns a Hash that maps from the tag index in the group to the oligo sequence for the tag
  def indexed_tags
    Hash[tags.map { |tag| [ tag.map_id, tag.oligo ] }]
  end
end
