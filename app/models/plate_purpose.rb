class PlatePurpose < ActiveRecord::Base
  class Relationship < ActiveRecord::Base
    set_table_name('plate_purpose_relationships')
    belongs_to :parent, :class_name => 'PlatePurpose'
    belongs_to :child, :class_name => 'PlatePurpose'

    module Associations
      def self.included(base)
        base.class_eval do
          has_many :child_relationships, :class_name => 'PlatePurpose::Relationship', :foreign_key => :parent_id, :dependent => :destroy
          has_many :child_plate_purposes, :through => :child_relationships, :source => :child

          has_many :parent_relationships, :class_name => 'PlatePurpose::Relationship', :foreign_key => :child_id, :dependent => :destroy
          has_many :parent_plate_purposes, :through => :parent_relationships, :source => :parent
        end
      end
    end
  end

  module Associations
    def self.included(base)
      base.class_eval do
        belongs_to :plate_purpose
        named_scope :with_plate_purpose, lambda { |*purposes|
          { :conditions => { :plate_purpose_id => purposes.flatten.map(&:id) } }
        }
      end
    end

    # Delegate the change of state to our plate purpose.
    def transition_to(state, contents = nil)
      plate_purpose.transition_to(self, state, contents)
    end
  end

  include Relationship::Associations

  named_scope :cherrypickable, :conditions => { :cherrypickable_target => true }

  # The state of a plate is based on the transfer requests.
  def state_of(plate)
    plate.send(:state_from, plate.transfer_requests)
  end

  # Updates the state of the specified plate to the specified state.  The basic implementation does this by updating
  # all of the TransferRequest instances to the state specified.  If contents is blank then the change is assumed to
  # relate to all wells of the plate, otherwise only the selected ones are updated.

  # Pulled from other assets. May need to be changed.
  STATE_TO_STATEMACHINE_EVENT = { 'started' => 'start!', 'passed' => 'pass!', 'failed' => 'fail!', 'cancelled' => 'cancel!', 'pending' => 'detach!' }
  # NOTE: Now changed to ensure transitions are ALWAYS used
  def transition_to(plate, state, contents = nil)
    wells = plate.wells
    wells = wells.located_at(contents) unless contents.blank?

    well_to_requests = wells.map { |well| [well, well.requests_as_target] }.reject { |_,r| r.empty? }
    requests = Request.find(:all, :conditions => [ 'id IN (?)', well_to_requests.map(&:last).flatten ])
    event    = STATE_TO_STATEMACHINE_EVENT[state] or raise StandardError, "Illegal transition state #{state.inspect}"
    requests.each {|request| request.send(event)}
    return unless state == 'failed'

    # Load all of the requests that come from the stock wells that should be failed.  Note that we can't simply change
    # their state, we have to actually use the statemachine method to do this to get the correct behaviour.
    conditions, parameters = [], []
    well_to_requests.each do |well, requests|
      submission_ids, stock_wells = requests.map(&:submission_id), well.stock_wells.map(&:id)
      next if stock_wells.empty?
      conditions << '(submission_id IN (?) AND asset_id IN (?))'
      parameters.concat([ submission_ids, stock_wells ])
    end
    Request.where_is_not_a?(TransferRequest).all(:conditions => [ "(#{conditions.join(' OR ')})", *parameters ]).map(&:fail!)
  end

  def pool_wells(wells)
    _pool_wells(wells).all(:select => 'assets.*, submission_id AS pool_id', :readonly => false).tap do |wells_with_pool|
      raise StandardError, "Cannot deal with a well in multiple pools" if wells_with_pool.group_by(&:id).any? { |_, multiple_pools| multiple_pools.uniq.size > 1 }
    end
  end

  def _pool_wells(wells)
    wells.pooled_as_target_by(TransferRequest)
  end
  private :_pool_wells

  include Api::PlatePurposeIO::Extensions
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable

  # There's a barcode printer type that has to be used to print the labels for this type of plate.
  belongs_to :barcode_printer_type

  def barcode_type
    barcode_printer_type.printer_type_id
  end

  has_many :plates #, :class_name => "Asset"
  acts_as_audited :on => [:destroy, :update]

  named_scope :considered_stock_plate, { :conditions => { :can_be_considered_a_stock_plate => true } }

  validates_format_of :name, :with => /^\w[\s\w._-]+\w$/i
  validates_presence_of :name
  validates_uniqueness_of :name, :message => "already in use"

  def target_plate_type
    self.target_type || 'Plate'
  end

  def self.stock_plate_purpose
    # IDs copied from SNP
    @stock_plate_purpose ||= PlatePurpose.find(2)
  end

  def create!(*args, &block)
    attributes          = args.extract_options!
    do_not_create_wells = !!args.first

    attributes[:size] ||= 96
    plates.create_with_barcode!(attributes, &block).tap do |plate|
      plate.wells.import(Map.where_plate_size(plate.size).in_reverse_row_major_order.all.map { |map| Well.new(:map => map) }) unless do_not_create_wells
    end
  end
end
