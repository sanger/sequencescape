class TagGroup < ActiveRecord::Base  
  has_many :tags
  acts_as_audited :on => [:destroy, :update]
  
  validates_presence_of :name
  include Uuid::Uuidable
  
  def create_tags(tags_properties)
    return if tags_properties.blank?
    tags_properties.each do |index,tag_properties|
      next if tag_properties[:oligo].blank?
      self.tags << Tag.create(tag_properties)
    end
  end
  
  def tags_sorted_by_map_id
    self.tags.sort{ |a,b| a.map_id <=> b.map_id }
  end

end
