# frozen_string_literal: true
# Allows the creation of multiple {Transfer::BetweenPlates} for a given array
# of individual transfers. Designed for use via the API
#
# @example Example usage
# BulkTransfer.create!({
#   well_transfers: [
#     {
#       source_uuid: source_plate1.uuid, source_location: 'A1',
#       destination_uuid: destination_plate1.uuid, destination_location: 'A1'
#     },
#     {
#       source_uuid: source_plate1.uuid, source_location: 'B1',
#       destination_uuid: destination_plate2.uuid, destination_location: 'A1'
#     },
#     {
#       source_uuid: source_plate2.uuid, source_location: 'A1',
#       destination_uuid: destination_plate1.uuid, destination_location: 'B1'
#     },
#     {
#       source_uuid: source_plate2.uuid, source_location: 'B1',
#       destination_uuid: destination_plate2.uuid, destination_location: 'B1'
#     }
#   ],
#   user: User.last
# })
#
# @deprecated Use TransferRequestCollection instead, which is more explicit and allows transfers between
# plates and tubes
class BulkTransfer < ApplicationRecord
  include Uuid::Uuidable

  has_many :transfers

  belongs_to :user
  validates :user, presence: true

  after_create :build_transfers!

  attr_accessor :well_transfers

  private

  def build_transfers!
    ActiveRecord::Base.transaction do
      each_transfer do |source, destination, transfers|
        Transfer::BetweenPlates.create!(
          source: source,
          destination: destination,
          user: user,
          transfers: transfers,
          bulk_transfer_id: id
        )
      end
    end
  end

  def each_transfer # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    well_transfers
      .group_by { |tf| [tf['source_uuid'], tf['destination_uuid']] }
      .each do |source_dest, all_transfers|
        transfers = Hash.new { |h, i| h[i] = [] }
        all_transfers.each { |t| transfers[t['source_location']] << t['destination_location'] }

        source = Uuid.find_by(external_id: source_dest.first).resource
        destination = Uuid.find_by(external_id: source_dest.last).resource
        errors.add(:source, 'is not a plate') unless source.is_a?(Plate)
        errors.add(:destination, 'is not a plate') unless destination.is_a?(Plate)
        raise ActiveRecord::RecordInvalid, self if errors.count > 0

        yield(source, destination, transfers)
      end
  end
end
