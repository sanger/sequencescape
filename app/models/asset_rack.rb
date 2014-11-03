class AssetRack < Asset

  include LocationAssociation::Locatable
  include Transfer::Associations
  include Barcode::Barcodeable
  include Asset::Ownership::Unowned
  extend QcFile::Associations
  has_qc_files

  # Yuck! Yuck! Yuck!
  self.prefix = "DN"

  named_scope :include_asset_rack_purpose, :include=>:purpose
  belongs_to :purpose, :class_name => 'AssetRack::Purpose', :foreign_key => :plate_purpose_id
  alias_method :asset_rack_purpose, :purpose

  delegate :default_state, :barcode_type, :asset_shape, :source_plate_purpose, :to => :purpose, :allow_nil => true

  contains :strip_tubes do

    def construct!
      # By default we name the strip tubes after the containing plate.
      # The transfer will later rename them after the source plate.
      strips = proxy_owner.maps.map do |map|
        {
          :name => "#{proxy_owner.sanger_human_barcode}:#{map.description}",
          :map  => map
        }
        proxy_owner.strip_tubes.build(strips)
        proxy_owner.save!
      end

    end

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
    ancestor_of_purpose(source_plate_purpose) || raise(StandardError,"No #{source_plate_purpose.name} ancestor identified.")
  end

  def priority
    Submission.find(:first,
      :select => 'MAX(submissions.priority) AS priority',
      :joins => [
        'INNER JOIN requests as reqp ON reqp.submission_id = submissions.id',
        'INNER JOIN container_associations AS caplp ON caplp.content_id = reqp.target_asset_id'
      ],
      :conditions => ['caplp.container_id IN (?)', strip_tubes.map(&:id)]
    ).try(:priority)||0
  end

  def self.create_with_barcode!(*args, &block)
    attributes = args.extract_options!
    barcode    = args.first || attributes[:barcode]
    barcode    = nil if barcode.present? and find_by_barcode(barcode).present?
    barcode  ||= PlateBarcode.create.barcode
    create!(attributes.merge(:barcode => barcode), &block)
  end

  # Transfer requests into a rack are the requests leading into the wells of said rack.
  def transfer_requests
    wells.all(:include => :transfer_requests_as_target).map(&:transfer_requests_as_target).flatten
  end

  class Purpose < ::Purpose

    has_many :asset_racks, :foreign_key => :plate_purpose_id, :inverse_of => :purpose
    belongs_to :asset_shape, :class_name => 'Map::AssetShape'

    def source_plate_purpose
      ::Purpose.find_by_name!('Cherrypicked')
    end


    def create!(*args, &block)
      attributes           = args.extract_options!
      do_not_create_strips = !!args.first

      attributes[:size]     ||= size
      attributes[:location] ||= default_location
      attributes[:purpose]    = self

      target_type.constantize.create_with_barcode!(attributes, &block).tap do |plate|
        plate.strip_tubes.construct! unless do_not_create_strips
      end
    end

  end

end
