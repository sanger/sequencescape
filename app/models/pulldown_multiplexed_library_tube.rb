class PulldownMultiplexedLibraryTube < Asset
  include LocationAssociation::Locatable

  named_scope :including_associations_for_json, { :include => [:uuid_object, :barcode_prefix ] }
  
  def is_a_pool?
    true
  end
  
  def parents_via_requests
    Request.find_all_by_target_asset_id(self.id).map(&:asset)
  end
  
  def tags
    self.parents_via_requests
  end
  
  def self.render_class
    Api::PulldownMultiplexedLibraryTubeIO
  end
end
