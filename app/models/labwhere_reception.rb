# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015,2016 Genome Research Ltd.

require 'lab_where_client'
# A simple class to handle the behaviour from the labwhere reception controller
class LabwhereReception
  # The following two modules include methods used by a number of rails
  # helpers, such that we can use them in eg. form_for
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_reader :asset_barcodes, :user_code, :location_barcode, :location_id

  validates :asset_barcodes, :user_code, :location, presence: true

  def initialize(user_code, location_barcode, location_id, asset_barcodes)
    @asset_barcodes = asset_barcodes.map(&:strip)
    @location_id = location_id.to_i
    @location_barcode = location_barcode.try(:strip)
    @user_code = user_code.try(:strip)
  end

  def location
     @location ||= Location.find_by(id: location_id)
  end

  def id; nil; end

  def persisted?; false; end

  def new_record?; true; end

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
      asset.location = location
      asset.events.create_scanned_into_lab!(location)
    end

    valid?
  end

  private

  def assets
    @assets ||= Asset.with_machine_barcode(asset_barcodes)
  end
end
