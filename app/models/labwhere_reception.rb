#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

# A simple class to handle the behaviour from the labwhere reception controller
class LabwhereReception

  attr_reader :errors, :asset_barcodes, :user_code, :location_barcode, :location_id

  def initialize(user_code,location_barcode,location_id,asset_barcodes)
    @asset_barcodes = asset_barcodes.map(&:strip)
    @location_id = location_id.to_i
    @location_barcode = location_barcode.try(:strip)
    @user_code = user_code.try(:strip)
    @errors = []
  end

  def location
     @location ||= Location.find_by_id(location_id)
  end

  def id; nil; end
  def new_record?; true; end

  # save attempts to perform the actions, and returns true if it was successful
  # This maintains compatibility with rails
  def save
    return false unless valid?

    begin
      scan = LabWhereClient::Scan.create(
        :location_barcode=> location_barcode,
        :user_code => user_code,
        :labware_barcodes => asset_barcodes
      )

      return add_error(scan.error) unless scan.valid?
    rescue LabWhereClient::LabwhereException => exception
      add_error("Could not connect to Labwhere. Sequencescape location has still been updated")
    end

    assets.each do |asset|
      asset.location = location
      asset.events.create_scanned_into_lab!(location)
    end

    @valid
  end

  private

  def valid?
    @valid = true
    add_error('Could not find specified location in Sequencescape') if location.nil?
    add_error("Could not find labware #{missing_assets.join(', ')} in Sequencescape") unless missing_assets.empty?
    add_error("No user supplied") if user_code.blank?
    add_error("No location scanned") if location_barcode.blank?
    @valid
  end

  def add_error(message)
    errors << message
    @valid = false
  end

  def assets
    @assets ||= Asset.with_machine_barcode(asset_barcodes)
  end

  def missing_assets
    add_error('No barcodes scanned in!') if asset_barcodes.empty?
    asset_barcodes - assets.map(&:machine_barcode)
  end

end
