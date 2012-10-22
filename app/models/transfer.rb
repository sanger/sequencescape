class Transfer < ActiveRecord::Base
  module Associations
    def self.included(base)
      base.class_eval do
        include Transfer::State

        has_many :transfers_as_source,     :class_name => 'Transfer', :foreign_key => :source_id,      :order => 'created_at ASC'
        has_many :transfers_to_tubes,      :class_name => 'Transfer::BetweenPlateAndTubes', :foreign_key => :source_id, :order => 'created_at ASC'
        has_one  :transfer_as_destination, :class_name => 'Transfer', :foreign_key => :destination_id

        # This looks odd but it's a LEFT OUTER JOIN, meaning that the rows we would be interested in have no source_id.
        named_scope :with_no_outgoing_transfers, {
          :select     => "DISTINCT #{base.quoted_table_name}.*",
          :joins      => "LEFT OUTER JOIN `transfers` outgoing_transfers ON outgoing_transfers.`source_id`=#{base.quoted_table_name}.`id`",
          :conditions => 'outgoing_transfers.source_id IS NULL'
        }
      end
    end
  end

  module State
    # These are all of the valid states but keep them in a priority order: in other words, 'started' is more important
    # than 'pending' when there are multiple requests (like a plate where half the wells have been started, the others
    # are failed).
    ALL_STATES = [ 'started', 'qc_complete', 'pending', 'passed', 'failed', 'cancelled' ]

    def self.state_helper(names)
      Array(names).each do |name|
        module_eval(%Q{def #{name}? ; state == #{name.to_s.inspect} ; end})
      end
    end

    state_helper(ALL_STATES)

    # The state of an asset is based on the transfer requests for the asset.  If they are all in the same
    # state then it takes that state.  Otherwise we take the "most optimum"!
    def state
      state_from(self.transfer_requests)
    end

    def state_from(state_requests)
      unique_states = state_requests.map(&:state).uniq
      return unique_states.first if unique_states.size == 1
      ALL_STATES.detect { |s| unique_states.include?(s) } || self.default_state || 'unknown'
    end
    private :state_from

    module PlateState
      def self.included(base)
        base.class_eval do
          named_scope :in_state, lambda { |states|
            states = Array(states).map(&:to_s)

            # If all of the states are present there is no point in actually adding this set of conditions because we're
            # basically looking for all of the plates.
            if states.sort != ALL_STATES.sort
              # NOTE: The use of STRAIGHT_JOIN here forces the most optimum query on MySQL, where it is better to reduce
              # assets to the plates, then look for the wells, rather than vice-versa.  The former query takes fractions
              # of a second, the latter over 60.
              query_conditions, joins = 'transfer_requests_as_target.state IN (?)', [
                "STRAIGHT_JOIN `container_associations` ON (`assets`.`id` = `container_associations`.`container_id`)",
                "INNER JOIN `assets` wells_assets ON (`wells_assets`.`id` = `container_associations`.`content_id`) AND (`wells_assets`.`sti_type` = 'Well')",
                "LEFT OUTER JOIN `requests` transfer_requests_as_target ON transfer_requests_as_target.target_asset_id = wells_assets.id AND (transfer_requests_as_target.`sti_type` IN (#{[TransferRequest, *Class.subclasses_of(TransferRequest)].map(&:name).map(&:inspect).join(',')}))"
              ]

              # Note that 'state IS NULL' is included here for plates that are stock plates, because they will not have any
              # transfer requests coming into their wells and so we can assume they are pending (from the perspective of
              # pulldown at least).
              query_conditions = 'transfer_requests_as_target.state IN (?)'
              if states.include?('pending')
                joins << "INNER JOIN `plate_purposes` ON (`plate_purposes`.`id` = `assets`.`plate_purpose_id`)"
                query_conditions << ' OR (transfer_requests_as_target.state IS NULL AND plate_purposes.can_be_considered_a_stock_plate=TRUE)'
              end

              { :joins => joins, :conditions => [ query_conditions, states ] }
            else
              { }
            end
          }
        end
      end
    end

    module TubeState
      def self.included(base)
        base.class_eval do
          named_scope :in_state, lambda { |states|
            states = Array(states).map(&:to_s)

            # If all of the states are present there is no point in actually adding this set of conditions because we're
            # basically looking for all of the plates.
            if states.sort != ALL_STATES.sort

              query_conditions, joins = 'transfer_requests_as_target.state IN (?)', [
                "LEFT OUTER JOIN `requests` transfer_requests_as_target ON transfer_requests_as_target.target_asset_id = `assets`.id AND (transfer_requests_as_target.`sti_type` IN (#{[TransferRequest, *Class.subclasses_of(TransferRequest)].map(&:name).map(&:inspect).join(',')}))"
              ]

              query_conditions = 'transfer_requests_as_target.state IN (?)'

              { :joins => joins, :conditions => [ query_conditions, states ] }
            else
              { }
            end
          }
          named_scope :without_finished_tubes, lambda { |purpose|
            {:conditions => ["NOT (plate_purpose_id IN (?) AND state = 'passed')", purpose.map(&:id) ]}
          }
        end
      end
    end
  end

  # The transfers are described in some manner, like direct transfers of one well to the same well on
  # another plate.
  module TransfersBySchema
    def self.included(base)
      base.class_eval do
        serialize :transfers
        validates_presence_of :transfers, :allow_blank => false
      end
    end
  end

  # The transfer goes from the source to a specified destination and this can only happen once.
  module TransfersToKnownDestination
    def self.included(base)
      base.class_eval do
        belongs_to :destination, :polymorphic => true
        validates_presence_of :destination
        validates_uniqueness_of :destination_id, :scope => [ :destination_type, :source_id ], :message => 'can only be transferred to once from the source'
      end
    end
  end

  # The transfer from the source is controlled by some mechanism other than user choice.  Essentially
  # an algorithmic transfer, which is recorded so we know what happened.
  module ControlledDestinations
    def self.included(base)
      base.class_eval do
        include Transfer::WellHelpers

        # Ensure that the transfers are recorded so we can see what happened.
        serialize :transfers
        validates_unassigned :transfers
      end
    end

    def each_transfer(&block)
      well_to_destination.each do |source, destination_and_additional_information|
        destination, *extra_information = Array(destination_and_additional_information)
        yield(source, destination)
        record_transfer(source, destination, *extra_information)
      end
    end
    private :each_transfer
  end

  module WellHelpers
    # To calculate the depth we keep walking the requests_as_target until we reach a plate that can be
    # considered a stock plate.
    def calculate_stock_well_depth_for(well)
      depth = -1    # Because we do not include the first well in our calculations!
      until well.plate.stock_plate?
        well   = well.requests_as_target.first.try(:asset) or raise StandardError, "Walked off the end of the graph!"
        depth += 1
      end
      depth
    end
    private :calculate_stock_well_depth_for
  end

  include Uuid::Uuidable

  self.inheritance_column   = "sti_type"

  # So we can track who is requesting the transfer
  belongs_to :user
  validates_presence_of :user

  # The source plate and the destination asset (which varies between different types of transfers)
  # You can only transfer from one plate to another once, anything else is an error.
  belongs_to :source, :class_name => 'Plate'
  validates_presence_of :source
  named_scope :include_source, :include => { :source => ModelExtensions::Plate::PLATE_INCLUDES }

  # Before creating an instance of this class the appropriate transfers need to be made from a source
  # asset to the destination one.
  before_create :create_transfer_requests
  def create_transfer_requests
    # TODO: This is probably actually a submission, which means we'll need project & study too
    each_transfer do |source, destination|
      request_type_between(source, destination).create!(
        :asset         => source,
        :target_asset  => destination,
        :submission_id => source.pool_id
      )
    end
  end
  private :create_transfer_requests

  def self.preview!(attributes)
    new(attributes) do |transfer|
      raise ActiveRecord::RecordInvalid, transfer unless transfer.valid?
      transfer.unsaved_uuid!
      transfer.send(:each_transfer) do |source, destination|
        # Needs to do nothing at all as the transfers will be recorded
      end
    end
  end

  # Determines if the well should not be transferred.
  def should_well_not_be_transferred?(well)
    well.nil? or well.aliquots.empty? or well.failed? or well.cancelled?
  end
  private :should_well_not_be_transferred?
end
