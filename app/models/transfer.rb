# frozen_string_literal: true

# A transfer handles the transfer of material from one piece of labware to another.
# Different classes are used to determine exactly how the transfers are performed.
# @note {TransferRequestCollection} is preferred, as it allows the client applications to control
#       the transfer behaviour.
class Transfer < ApplicationRecord
  include Uuid::Uuidable

  self.inheritance_column = 'sti_type'

  # So we can track who is requesting the transfer
  belongs_to :user
  validates :user, presence: true

  # The source plate and the destination asset (which varies between different types of transfers)
  # You can only transfer from one plate to another once, anything else is an error.
  belongs_to :source, class_name: 'Plate'
  validates :source, presence: true
  # scope :include_source, -> { includes(source: ModelExtensions::Plate::PLATE_INCLUDES) }

  belongs_to :destination, class_name: 'Labware'

  # Before creating an instance of this class the appropriate transfers need to be made from a source
  # asset to the destination one.
  before_create :create_transfer_requests

  def self.preview!(attributes)
    new(attributes) do |transfer|
      raise ActiveRecord::RecordInvalid, transfer unless transfer.valid?

      transfer.unsaved_uuid!
      transfer.send(:each_transfer) do |source, destination|
        # Needs to do nothing at all as the transfers will be recorded
      end
    end
  end

  #
  # Given a list of well  map_descriptions (eg. A1) validates that all are present on the
  # plate, otherwise generates a validation error. Also valid if the plate is not specified.
  # Used by: {Transfer::BetweenPlates} and {Transfer::FromPlateToTube}
  #
  # @param [Array] positions Array of map_descriptions to test
  #
  def validate_transfers(positions, plate, plate_type)
    invalid_positions = plate&.invalid_positions(positions)
    return true if invalid_positions.blank? # We either have no plate, or all positions are valid

    errors.add(:transfers, "#{invalid_positions.join(', ')} are not valid positions for the #{plate_type} plate")
  end

  private

  def create_transfer_requests
    # NOTE: submission is optional. Unlike methods, blocks don't support default argument
    # values, but any attributes not yielded will be nil. Apparently 1.9 is more consistent
    each_transfer do |source, destination, submission|
      TransferRequest.create!(asset: source, target_asset: destination, submission_id: submission || source.pool_id)
    end
  end

  # Determines if the well should not be transferred.
  def should_well_not_be_transferred?(well)
    well.nil? or well.aliquots.empty? or well.failed? or well.cancelled?
  end
end

# Required for the descendants method to work when eager loading is off in test
require_dependency 'transfer/between_plate_and_tubes'
require_dependency 'transfer/between_plates_by_submission'
require_dependency 'transfer/between_plates'
require_dependency 'transfer/between_specific_tubes'
require_dependency 'transfer/between_tubes_by_submission'
require_dependency 'transfer/from_plate_to_specific_tubes_by_pool'
require_dependency 'transfer/from_plate_to_specific_tubes'
require_dependency 'transfer/from_plate_to_tube_by_multiplex'
require_dependency 'transfer/from_plate_to_tube_by_submission'
require_dependency 'transfer/from_plate_to_tube'
