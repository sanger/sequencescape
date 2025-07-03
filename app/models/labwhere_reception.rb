# frozen_string_literal: true
require 'lab_where_client'
# A simple class to handle the behaviour from the labwhere reception controller
class LabwhereReception
  # The following two modules include methods used by a number of rails
  # helpers, such that we can use them in eg. form_for
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_reader :asset_barcodes, :user_code, :location_barcode

  validates :asset_barcodes, :user_code, presence: true
  validates :user,
            presence: {
              message:
                'could not be found with that swipecard or barcode. ' \
                'You may need to update your swipecard in Sequencescape.'
            }

  def initialize(user_code, location_barcode, asset_barcodes)
    @asset_barcodes = (asset_barcodes || []).map(&:strip)
    @location_barcode = location_barcode.try(:strip)
    @user_code = user_code.try(:strip)
  end

  def id
    nil
  end

  def persisted?
    false
  end

  def new_record?
    true
  end

  def user
    @user ||= User.find_with_barcode_or_swipecard_code(@user_code)
  end

  # save attempts to perform the actions, and returns true if it was successful
  # This maintains compatibility with rails
  # rubocop:todo Metrics/MethodLength
  def save # rubocop:todo Metrics/AbcSize
    return false unless valid?

    begin
      scan =
        LabWhereClient::Scan.create(
          location_barcode: location_barcode,
          user_code: user_code,
          labware_barcodes: asset_barcodes
        )

      unless scan.valid?
        # Prepend the errors with 'Labwhere' to make it clear where the error came from
        # This is important as you can get both Sequencescape and Labwhere errors of the same type
        # e.g. User does not exist
        labwhere_errors = scan.errors.map { |error| "LabWhere #{error}" }
        errors.add(:base, labwhere_errors)
        return false
      end
    rescue LabWhereClient::LabwhereException => e
      errors.add(:base, 'Could not connect to Labwhere.')
      return false
    end

    assets.each do |asset|
      asset.events.create_scanned_into_lab!(location_barcode, user.login)
      BroadcastEvent::LabwareReceived.create!(seed: asset, user: user, properties: { location_barcode: })
    end

    valid?
  end

  # rubocop:enable Metrics/MethodLength

  def assets
    @assets ||= Labware.with_barcode(asset_barcodes)
  end

  def missing_barcodes
    machine_barcodes = assets.to_set(&:machine_barcode)
    human_barcodes = assets.to_set(&:human_barcode)
    asset_barcodes.delete_if { |barcode| human_barcodes.include?(barcode) || machine_barcodes.include?(barcode) }
  end
end
