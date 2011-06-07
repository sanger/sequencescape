class LibraryTube < Asset
  include ModelExtensions::LibraryTube
  include LocationAssociation::Locatable

  named_scope :including_associations_for_json, { :include => [ :uuid_object, { :tag_instance => { :tag => [ :uuid_object, { :tag_group => :uuid_object } ] } },  {:source_request => [:uuid_object, :request_metadata] }, :barcode_prefix, { :sample => :uuid_object }] }
  @@per_page = 500

  def url_name
    "library_tube"
  end
  alias_method(:json_root, :url_name)

  def is_sequenceable?
    true
  end

  def is_a_pool?
    false
  end

  has_one :tag_instance, :through => :links_as_child, :source => :ancestor, :conditions => { :sti_type => 'TagInstance' }
  named_scope :include_tag, :include => { :tag_instance => { :tag => [ :uuid_object, { :tag_group => :uuid_object } ] } }

  def tag_instance=(tag_instance)
    raise RuntimeError, "Tag instance must be saved beforehand" unless tag_instance.id
    old_tag_instance = get_tag_instance
    if old_tag_instance
      self.parents.delete(old_tag_instance)
    end

    AssetLink.create_edge(tag_instance, self)
  end

  def get_tag_instance
    self.tag_instance
  end
  
  def get_tag
    self.tag_instance.try(:tag)
  end

  def tag
    self.get_tag.try(:map_id) || ''
  end
  
  def sorted_tags_for_select
    self.get_tag.tag_group.tags.sort{ |a,b| a.map_id <=> b.map_id }.collect { |t| [t.name, t.id] }
  end

  # A library tube is created with request options that come from the request in which it is the target asset.
  def created_with_request_options
    creation_request.try(:request_options_for_creation) || {}
  end

  def has_stock_asset?
   parent_asset_types = self.parents.map(&:sti_type)
   if parent_asset_types.include?("StockLibraryTube")
     return true
   else
     return false
   end
  end

  def is_a_stock_asset?
   false
  end

  def new_stock_asset
   StockLibraryTube.new(:name => "(s) #{self.name}", :sample_id => self.sample_id, :barcode => AssetBarcode.new_barcode)
  end
  
  def stock_asset
    self.parents.detect{ |a| a.sti_type == "StockLibraryTube" }
  end
  
  def self.render_class
    Api::LibraryTubeIO
  end
  
end
