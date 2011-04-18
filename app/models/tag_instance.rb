class TagInstance < Asset
  def self.render_class
    Api::TagInstanceIO
  end
	
	named_scope :including_associations_for_json, { :include => [ :uuid_object, :barcode_prefix, { :tag => [:tag_group, :uuid_object ] } ] }

  # We do not, ever, hold a sample so we make it really hard for people to do it
  attr_protected :sample_id
  undef sample
  undef sample=

  # We do, however, hold a tag!
  belongs_to :tag
  alias_attribute(:material, :tag)
  alias_attribute(:material_id, :tag_id)
  def material_type ; Tag.name ; end

  def move_all_asset_group(study_from, study_to, asset_visited, asset_group, current_user)
     return
  end
  
  def list_sample_tube(asset_visited, sampletube_list)
    return
  end

end
