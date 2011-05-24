class Transfer < ActiveRecord::Base
  include Uuid::Uuidable

  # So we can track who is requesting the transfer
  belongs_to :user

  # The source plate and the destination asset (which varies between different types of transfers)
  belongs_to :source, :class_name => 'Plate'
  validates_presence_of :source

  belongs_to :destination, :polymorphic => true
  validates_presence_of :destination

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

    # Something is incredibly screwed in acts_as_dag because you can't just push the destination onto
    # the source.children association.
    AssetLink.create_edge(self.source, self.destination)
  end
  private :create_transfer_requests

  def well_from(plate, location)
    plate.wells.detect { |well| well.map.description == location }
  end
  private :well_from
end
