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

  has_one_as_child :tag_instance, :conditions => { :sti_type => 'TagInstance' }
  named_scope :include_tag, :include => { :tag_instance => { :tag => [ :uuid_object, { :tag_group => :uuid_object } ] } }

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

  has_one_as_child(:stock_asset, :conditions => { :sti_type => 'StockLibraryTube' })

  def is_a_stock_asset?
    false
  end

  def new_stock_asset
    StockLibraryTube.new(:name => "(s) #{self.name}", :sample_id => self.sample_id, :barcode => AssetBarcode.new_barcode)
  end

  def self.render_class
    Api::LibraryTubeIO
  end
end
