class LibraryTube < Tube
  include Api::LibraryTubeIO::Extensions
  include ModelExtensions::LibraryTube

  def is_sequenceable?
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

  has_one_as_child(:stock_asset, :conditions => { :sti_type => 'StockLibraryTube' })

  def is_a_stock_asset?
    false
  end

  def create_stock_asset!(attributes = {}, &block)
    StockLibraryTube.create!(attributes.reverse_merge(:name => "(s) #{self.name}", :barcode => AssetBarcode.new_barcode), &block).tap do |stock_asset|
      stock_asset.aliquots = aliquots.map(&:clone)
    end
  end

  def new_stock_asset
    StockLibraryTube.new(:name => "(s) #{self.name}", :sample_id => self.sample_id, :barcode => AssetBarcode.new_barcode)
  end
  deprecate :new_stock_asset
end
