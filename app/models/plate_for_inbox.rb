
require "#{Rails.root}/app/models/illumina_b/requests"
require "#{Rails.root}/app/models/illumina_c/requests"
require "#{Rails.root}/app/models/illumina_htp/requests"
require "#{Rails.root}/app/models/pulldown/requests"


class PlateForInbox < ActiveRecord::Base

  # Our inbox only needs a limited subset of plate information, and building it using the standard plate model
  # is slow and cumbersome. This model builds most the information we need in a single query, and uses a simplified
  # endpoint to restrict it down to the vital information only

  # We'll have some difficulty eager loading the stock_plates, due to a bit of dynamic stuff going on in some of the
  # plate purposes.

  include Barcode::Barcodeable
  include Asset::Ownership::Owned
  include AssetLink::Associations
  include LocationAssociation::Locatable
  include Plate::Iterations

  def readonly?; true; end
  def before_destroy; raise ActiveRecord::ReadOnlyRecord; end

  def self.state_order
    Transfer::State::ALL_STATES
  end

  def self.terminal_states
    ['cancelled','failed']
  end

  set_table_name('assets')
  default_scope(
    :select => ['assets.id AS id, ',
      'assets.name AS name, ',
      'pfiuu.external_id AS uuid, ',
      'assets.barcode AS barcode, ',
      'assets.barcode_prefix_id AS barcode_prefix_id, ',
      # Find the most advanced incomming request
      "MIN(FIND_IN_SET(pfir.state,'#{state_order.join(',')}')) AS state_index, ",
      # Are all the outgoing requests cancelled (Stock plates only)
      "BIT_AND(FIND_IN_SET(pfilcr.state,'failed,cancelled')>0)=1 AS cancelled_requests, ",
      # What's the highest priority submission. 0 if none specified
      'IFNULL(MAX(pfis.priority),0) AS priority, ',
      'assets.created_at AS created_at, ',
      'assets.updated_at AS updated_at, ',
      'pfip.name AS plate_purpose_name, ',
      'pfip.can_be_considered_a_stock_plate AS a_stock_plate, ',
      'assets.plate_purpose_id AS plate_purpose_id',
      ],
    :include => [:plate_purpose, :barcode_prefix],
    :joins => [
      'INNER JOIN uuids AS pfiuu ON pfiuu.resource_id = assets.id AND pfiuu.resource_type = "Asset"',
      'STRAIGHT_JOIN container_associations AS pfica ON pfica.container_id = assets.id',
      "LEFT OUTER JOIN requests AS pfir ON pfir.target_asset_id = pfica.content_id AND (pfir.`sti_type` IN (#{[TransferRequest, *Class.subclasses_of(TransferRequest)].map(&:name).map(&:inspect).join(',')}))",
      'INNER JOIN plate_purposes AS pfip ON assets.plate_purpose_id = pfip.id',
      "LEFT OUTER JOIN requests AS pfilcr ON pfip.can_be_considered_a_stock_plate = TRUE AND pfilcr.asset_id = pfica.content_id AND (pfilcr.`sti_type` IN (#{[Request::LibraryCreation, *Class.subclasses_of(Request::LibraryCreation)].map(&:name).map(&:inspect).join(',')}))",
      'LEFT OUTER JOIN submissions AS pfis ON pfis.id = pfir.submission_id OR pfis.id = pfilcr.submission_id'
    ],
    :conditions => [
      'assets.sti_type IN (?)',
      ['Plate'] + Class.subclasses_of(Plate).map(&:name)
    ],
    :group => 'assets.id',
    :readonly => true
  )

  belongs_to :plate_purpose
  belongs_to :barcode_prefix

  def prefix
    barcode_prefix.prefix
  end

  def source_plate
    plate_purpose.source_plate(self)
  end

  def stock_plate
    @stock_plate ||= a_stock_plate==1 ? self : lookup_stock_plate
  end

  def parent
    self.parents.first
  end

  def lookup_stock_plate
    self.ancestors.find(:first,
      :select => 'barcode, barcode_prefix_id, sti_type',
      :joins  => 'INNER JOIN plate_purposes ON plate_purposes.id = assets.plate_purpose_id',
      :conditions => 'plate_purposes.can_be_considered_a_stock_plate = TRUE',
      :order => 'asset_links.created_at DESC'
    )
  end
  private :lookup_stock_plate

  named_scope :with_plate_purpose, lambda {|purposes| { :conditions => {:plate_purpose_id=>purposes.map(&:id)}} }
  named_scope :in_state, lambda {|states|
    if states.sort != PlateForInbox.state_order.sort
      { :having => ['state_index IN (?) OR (a_stock_plate=TRUE AND cancelled_requests=FALSE)', states.map {|s| PlateForInbox.state_order.index(s)+1} ] }
    else
      {}
    end
  }
  named_scope :with_no_outgoing_transfers, {
    :joins      => "LEFT OUTER JOIN `transfers` outgoing_transfers ON outgoing_transfers.`source_id`=assets.`id`",
    :conditions => 'outgoing_transfers.source_id IS NULL'
  }

  def state
    plate_purpose.state_of(self)
  end

  def state_from(_)
    PlateForInbox.state_order[state_index-1||0]
  end

  def wells
    Plate.find(self.id).wells
  end

  def transfer_requests; end

end
