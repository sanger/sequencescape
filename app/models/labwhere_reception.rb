
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

  def initialize(user_code, location_barcode, asset_barcodes)
    @asset_barcodes = (asset_barcodes || []).map(&:strip)
    @location_barcode = location_barcode.try(:strip)
    @user_code = user_code.try(:strip)
  end

  def id; nil; end

  def persisted?; false; end

  def new_record?; true; end

  def user
    @user ||= User.find_with_barcode_or_swipecard_code(@user_code)
  end

  # save attempts to perform the actions, and returns true if it was successful
  # This maintains compatibility with rails
  def save
    return false unless valid?

   

    begin
      scan = LabWhereClient::Scan.create(
        location_barcode: location_barcode,
        user_code: user_code,
        labware_barcodes: asset_barcodes
      )

      unless scan.valid?
        errors.add(:scan, scan.error)
        return false
      end
    rescue LabWhereClient::LabwhereException => exception
      errors.add(:base, 'Could not connect to Labwhere. Sequencescape location has still been updated')
      return false
    end

    assets.each do |asset|
      asset.events.create_scanned_into_lab!(location_barcode, user.login)
      BroadcastEvent::LabwareReceived.create!(seed: asset, user: user, properties: { location_barcode: location_barcode })
    end

    valid?
  end

  def assets
    @assets ||= Asset.with_barcode(asset_barcodes)
  end

  def missing_barcodes
    asset_barcodes - @assets.map(&:ean13_barcode)
  end
end
