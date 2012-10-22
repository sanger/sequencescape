class LibraryTube < Tube
  include Api::LibraryTubeIO::Extensions
  include ModelExtensions::LibraryTube

  def is_sequenceable?
    true
  end

  def library_prep?
    true
  end

  named_scope :include_tag, :include => { :aliquots => { :tag => [ :uuid_object, { :tag_group => :uuid_object } ] } }

  def sorted_tags_for_select
    self.get_tag.tag_group.tags.sort{ |a,b| a.map_id <=> b.map_id }.collect { |t| [t.name, t.id] }
  end

  # A library tube is created with request options that come from the request in which it is the target asset.
  def created_with_request_options
    creation_request.try(:request_options_for_creation) || {}
  end

  def self.stock_asset_type
    StockLibraryTube
  end

  extend Asset::Stock::CanCreateStockAsset
end
