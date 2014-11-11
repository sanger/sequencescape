class AssetRack < Asset

  include LocationAssociation::Locatable
  include Transfer::Associations
  include Barcode::Barcodeable
  include Asset::Ownership::Owned
  extend QcFile::Associations
  has_qc_files

  # Yuck! Yuck! Yuck!
  self.prefix = "DN"

  named_scope :include_asset_rack_purpose, :include=>:purpose

  belongs_to :purpose, :class_name => 'AssetRack::Purpose', :foreign_key => :plate_purpose_id
  alias_method :asset_rack_purpose, :purpose

  delegate :default_state, :to => :purpose, :allow_nil => true
  delegate :barcode_type, :to => :purpose, :allow_nil => true
  delegate :asset_shape, :to => :purpose, :allow_nil => true

  contains :strip_tubes do

  end

  def wells
    AssetRack::WellAssociations::WellProxy.new(self)
  end

  def ancestor_of_purpose(purpose)
    self.ancestors.first(:order => 'created_at DESC', :conditions => {:plate_purpose_id=>purpose})
  end

  def lookup_stock_plate
    ancestor_of_purpose(PlatePurpose.find(:all,:conditions=>{:can_be_considered_a_stock_plate=>true}))
  end
  private :lookup_stock_plate

  # AssetRacks won't be stock plates any time soon
  alias_method :stock_plate, :lookup_stock_plate

  def source_plate
    ancestor_of_purpose(source_plate_purpose)
  end

  def source_plate_purpose
    Purpose.find_by_name('Cherrypicked')
  end

  def priority
    Submission.find(:first,
      :select => 'MAX(submissions.priority) AS priority',
      :joins => [
        'INNER JOIN requests as reqp ON reqp.submission_id = submissions.id',
        'INNER JOIN container_associations AS caplp ON caplp.content_id = reqp.target_asset_id'
      ],
      :conditions => ['caplp.container_id IN (?)',self.strip_tubes.map(&:id)]
    ).try(:priority)||0
  end

  # Transfer requests into a plate are the requests leading into the wells of said plate.
  def transfer_requests
    wells.all(:include => :transfer_requests_as_target).map(&:transfer_requests_as_target).flatten
  end

  class Purpose < ::Purpose

    has_many :asset_racks, :foreign_key => :plate_purpose_id, :inverse_of => :purpose
    belongs_to :asset_shape, :class_name => 'Map::AssetShape'

  end

end
