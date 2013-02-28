class BulkTransfer < ActiveRecord::Base
  include Uuid::Uuidable

  has_many :transfers

  belongs_to :user
  validates_presence_of :user

  after_create :build_transfers!

  attr_accessor :well_transfers

  def build_transfers!
    each_transfer do |source_uuid,destination_uuid,transfers|
      Transfer::BetweenPlates.create!(
        :source=>Uuid.find_by_external_id(source_uuid).resource,
        :destination=>Uuid.find_by_external_id(destination_uuid).resource,
        :user => user,
        :transfers => transfers,
        :bulk_transfer_id => self.id
      )
    end
  end
  private :build_transfers!

  def each_transfer
    well_transfers.group_by { |tf| [tf["source_uuid"],tf["destination_uuid"]] }.each do |source_dest, all_transfers|
      transfers = {}
      all_transfers.each {|t| transfers[t["source_location"]] = t["destination_location"] }
      yield (source_dest.first,source_dest.last,transfers)
    end
  end
  private :each_transfer

end
