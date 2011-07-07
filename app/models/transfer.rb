class Transfer < ActiveRecord::Base
  module Associations
    def self.included(base)
      base.class_eval do
        include Transfer::State

        has_many :transfers_as_source,     :class_name => 'Transfer', :foreign_key => :source_id,      :order => 'created_at ASC'
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
    ALL_STATES = [ 'pending', 'started', 'passed', 'failed', 'cancelled' ].sort

    def self.included(base)
      base.class_eval do
        named_scope :in_state, lambda { |states|
          states = Array(states).map(&:to_s)

          # If all of the states are present there is no point in actually adding this set of conditions because we're
          # basically looking for all of the plates.
          if states.sort != ALL_STATES
            # Note that 'state IS NULL' is included here for plates that are stock plates, because they will not have any 
            # transfer requests coming into their wells and so we can assume they are pending (from the perspective of
            # pulldown at least).
            query_conditions = 'transfer_requests_as_target.state IN (?)'
            query_conditions << ' OR transfer_requests_as_target.state IS NULL' if states.include?('pending')

            {
              :joins      => [
                "INNER JOIN `container_associations` ON (`assets`.`id` = `container_associations`.`container_id`)",
                "INNER JOIN `assets` wells_assets ON (`wells_assets`.`id` = `container_associations`.`content_id`) AND (`wells_assets`.`sti_type` = 'Well')",
                "LEFT OUTER JOIN `requests` transfer_requests_as_target ON transfer_requests_as_target.target_asset_id = wells_assets.id AND (transfer_requests_as_target.`sti_type` = 'TransferRequest')"
              ],
              :conditions => [ query_conditions, states ]
            }
          else
            { }
          end
        }
      end
    end

    def self.state_helper(*names)
      names.each do |name|
        module_eval(%Q{def #{name}? ; state == #{name.to_s.inspect} ; end})
      end
    end

    state_helper(ALL_STATES)

    # The state of an asset is based on the transfer requests for the asset.  If they are all in the same
    # state then it takes that state.  Otherwise we take the "most optimum"!
    def state
      state_requests = self.transfer_requests

      # If there is only one state then it's obviously that ...
      unique_states = state_requests.map(&:state).uniq
      return unique_states.first if unique_states.size == 1

      # These are the prioritised states.  Started overrides pending, which overrides passed, which
      # overrides failed or cancelled (we don't really care which!).
      case
      when unique_states.include?('started')   then 'started'
      when unique_states.include?('pending')   then 'pending'
      when unique_states.include?('passed')    then 'passed'
      when unique_states.include?('failed')    then 'failed'
      when unique_states.include?('cancelled') then 'cancelled'
      else self.default_state || 'unknown'
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

    def well_from(plate, location)
      plate.wells.detect { |well| well.map.description == location }
    end
    private :well_from
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
      well_to_destination.each do |source, destination|
        yield(source, destination)
        record_transfer(source, destination)
      end
    end
    private :each_transfer
  end

  module WellHelpers
    def locate_stock_well_for(current_well)
      return current_well if current_well.plate.plate_purpose.can_be_considered_a_stock_plate?

      while true
        previous_well =
          current_well.requests_as_target.where_is_a?(TransferRequest).first.try(:asset) or
            return nil
        return previous_well if previous_well.plate.plate_purpose.can_be_considered_a_stock_plate?
        current_well = previous_well
      end
    end
    private :locate_stock_well_for
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

  # Before creating an instance of this class the appropriate transfers need to be made from a source
  # asset to the destination one.
  before_create :create_transfer_requests
  def create_transfer_requests
    # TODO: This is probably actually a submission, which means we'll need project & study too
    each_transfer do |source, destination|
      TransferRequest.create!(:asset => source, :target_asset => destination)
    end
  end
  private :create_transfer_requests

  def self.preview!(attributes)
    new(attributes) do |transfer|
      raise ActiveRecord::RecordInvalid, transfer unless transfer.valid?
      transfer.send(:each_transfer) do |source, destination|
        # Needs to do nothing at all as the transfers will be recorded
      end
    end
  end
end
