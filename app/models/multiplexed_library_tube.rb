class MultiplexedLibraryTube < Asset
  include LocationAssociation::Locatable
  named_scope :including_associations_for_json, { :include => [:uuid_object, :barcode_prefix ] }
  def is_a_pool?
    true
  end

  # A multiplexed library tube is created with the request options of it's parent library tubes.  In effect
  # all of the parent library tubes have the same details, we only need take the first one.
  delegate :created_with_request_options, :to => 'parents.first'

  # You can do sequencing with this asset type, even though the request types suggest otherwise!
  def is_sequenceable?
    true
  end

  # Returns the type of asset that can be considered appropriate for request types.
  def asset_type_for_request_types
    LibraryTube
  end

  def has_stock_asset?
    parent_asset_types = self.parents.map(&:sti_type)
    if parent_asset_types.include?("StockMultiplexedLibraryTube")
      return true
    else
      return false
    end
  end

  def is_a_stock_asset?
    false
  end

  def new_stock_asset
    stock = StockMultiplexedLibraryTube.new(:name => "(s) #{self.name}", :barcode => AssetBarcode.new_barcode)
  end

  def stock_asset
    self.parents.detect{ |a| a.sti_type == "StockMultiplexedLibraryTube" }
  end
  
  def related_resources
      ['parents','children','requests']
  end
  
  def self.render_class
    Api::MultiplexedLibraryTubeIO
  end
  
  def url_name
    "multiplexed_library_tube"
  end
  alias_method(:json_root, :url_name)
  
  def tags
    if parent = self.parents.detect{ |parent| parent.is_a_stock_asset? }
        parent.parents
    else
      self.parents
    end
  end
end
