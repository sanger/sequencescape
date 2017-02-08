# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2015,2016 Genome Research Ltd.

module Submission::AssetSubmissionFinder
  def is_plate?(details)
    details['barcode'].present? and details['plate well'].present?
  end

  def is_tube?(details)
    details['barcode'].present? and details['plate well'].blank?
  end

  def find_all_assets_by_id_or_name_including_samples!(ids, names)
    return Aliquot::Receptacle.including_samples.find(*ids) unless ids.blank?
    raise StandardError, 'Must specify at least an ID or a name' if names.blank?
    Aliquot::Receptacle.including_samples.where(name: names).tap do |found|
      missing = names - found.map(&:name)
      raise ActiveRecord::RecordNotFound, "Could not find #{name} with names #{missing.inspect}" unless missing.blank?
    end
  end

  def find_wells_including_samples_for!(details)
    barcodes, well_list = details['barcode'], details['plate well']
    errors.add(:spreadsheet, 'You can only specify one plate per asset group') unless barcodes.uniq.one?
    barcode = barcodes.first

    match = /^([A-Z]{2})(\d+)[A-Z]$/.match(barcode) or raise StandardError, 'Plate Barcode should be human readable (e.g. DN111111K)'
    prefix = BarcodePrefix.find_by(prefix: match[1]) or raise StandardError, "Cannot find barcode prefix #{match[1].inspect} for #{details['rows']}"
    plate  = Plate.find_by(barcode_prefix_id: prefix.id, barcode: match[2]) or raise StandardError, "Cannot find plate with barcode #{barcode} for #{details['rows']}"

    well_locations = well_list.map(&:strip)
    wells = plate.wells.including_samples.located_at(well_locations)
    raise StandardError, "Too few wells found for #{details['rows']}: #{wells.map(&:map).map(&:description).inspect}" if wells.length != well_locations.size
    wells
  end

  def find_tubes_including_samples_for!(details)
    prefix_cache = Hash.new { |cache, prefix| cache[prefix] = BarcodePrefix.find_by(prefix: prefix) }

    details['barcode'].map do |barcode|
      match = /^([A-Z]{2})(\d+)[A-Z]$/.match(barcode) or raise StandardError, 'Tube Barcode should be human readable (e.g. NT2P)'
      prefix = prefix_cache[match[1]] or raise StandardError, "Cannot find barcode prefix #{match[1].inspect} for #{details['rows']}"
      Tube.including_samples.find_by(barcode_prefix_id: prefix.id, barcode: match[2]) or raise StandardError, "Cannot find tube with barcode #{barcode} for #{details['rows']}."
    end
  end
end
