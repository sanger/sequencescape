class Transfer < ActiveRecord::Base
  module Associations
    def self.included(base)
      base.class_eval do
        has_many :transfers_as_source,     :class_name => 'Transfer', :foreign_key => :source_id,      :order => 'created_at ASC'
        has_one  :transfer_as_destination, :class_name => 'Transfer', :foreign_key => :destination_id
      end
    end

    # The state of an asset is based on the transfer requests for the asset.  If they are any that are failed
    # or cancelled then this plate is cancelled; if there are requests and they are all started then the
    # plate is also started; otherwise the plate can be considered pending.
    def state
      state_requests = self.transfer_requests
      case
      when state_requests.any?(&:failed?)                            then 'failed'
      when state_requests.any?(&:cancelled?)                         then 'cancelled'
      when !state_requests.empty? && state_requests.all?(&:started?) then 'started'
      else                                                                'pending'
      end
    end
  end

  include Uuid::Uuidable

  self.inheritance_column = "sti_type"

  # So we can track who is requesting the transfer
  belongs_to :user

  # The source plate and the destination asset (which varies between different types of transfers)
  # You can only transfer from one plate to another once, anything else is an error.
  belongs_to :source, :class_name => 'Plate'
  validates_presence_of :source

  # It is only possible to transfer from a source to a destination once.
  belongs_to :destination, :polymorphic => true
  validates_presence_of :destination
  validates_uniqueness_of :destination_id, :scope => [ :destination_type, :source_id ], :message => 'can only be transferred to once from the source'

  # Transfers are described based on the implementation but the general information is contained
  # in this serialized column and cannot be empty.
  serialize :transfers
  validates_presence_of :transfers, :allow_blank => false

  # After creating an instance of this class the appropriate transfers need to be made from a source
  # asset to the destination one.
  after_create :create_transfer_requests
  def create_transfer_requests
    # TODO: This is probably actually a submission, which means we'll need project & study too
    each_transfer do |source, destination|
      TransfertRequest.create!(:asset => source, :target_asset => destination)
    end
  end
  private :create_transfer_requests

  def well_from(plate, location)
    plate.wells.detect { |well| well.map.description == location }
  end
  private :well_from
end
