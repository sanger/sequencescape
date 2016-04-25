module Submission::AssetSubmissionFinder
  def is_plate?(details)
    details['barcode'].present? and details['plate well'].present?
  end

  def is_tube?(details)
    details['barcode'].present? and details['plate well'].blank?
  end

  def find_all_assets_by_id_or_name_including_samples!(ids, names)
    return Asset.find(*ids) unless ids.blank?
    raise StandardError, "Must specify at least an ID or a name" if names.blank?
    Asset.find_all_by_name(names).tap do |found|
      missing = names - found.map(&:name)
      raise ActiveRecord::RecordNotFound, "Could not find #{self.name} with names #{missing.inspect}" unless missing.blank?
    end
  end

  def find_wells_including_samples_for!(details)
    barcodes, well_list = details['barcode'], details['plate well']
    self.errors.add(:spreadsheet, "You can only specify one plate per asset group") unless barcodes.uniq.one?
    barcode = barcodes.first

    match = /^([A-Z]{2})(\d+)[A-Z]$/.match(barcode) or raise StandardError, "Plate Barcode should be human readable (e.g. DN111111K)"
    prefix = BarcodePrefix.find_by_prefix(match[1]) or raise StandardError, "Cannot find barcode prefix #{match[1].inspect} for #{details['rows']}"
    plate  = Plate.find_by_barcode_prefix_id_and_barcode(prefix.id, match[2]) or raise StandardError, "Cannot find plate with barcode #{barcode} for #{details['rows']}"

    well_locations = well_list.map(&:strip)
    wells = plate.wells.including_samples.located_at(well_locations)
    raise StandardError, "Too few wells found for #{details['rows']}: #{wells.map(&:map).map(&:description).inspect}" if wells.length != well_locations.size
    wells
  end

  def find_tubes_including_samples_for!(details)
    details['barcode'].map do |barcode|
      match = /^([A-Z]{2})(\d+)[A-Z]$/.match(barcode) or raise StandardError, "Tube Barcode should be human readable (e.g. NT2P)"
      prefix = BarcodePrefix.find_by_prefix(match[1]) or raise StandardError, "Cannot find barcode prefix #{match[1].inspect} for #{details['rows']}"
      plate  = Tube.find_by_barcode_prefix_id_and_barcode(prefix.id, match[2]).including_samples or raise StandardError, "Cannot find tube with barcode #{barcode} for #{details['rows']}."
    end
  end
end
