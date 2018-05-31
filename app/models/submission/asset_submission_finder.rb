
module Submission::AssetSubmissionFinder
  def is_plate?(details)
    details['barcode'].present? and details['plate well'].present?
  end

  def is_tube?(details)
    details['barcode'].present? and details['plate well'].blank?
  end

  def find_all_assets_by_id_or_name_including_samples!(ids, names)
    return Receptacle.including_samples.find(*ids) if ids.present?
    raise StandardError, 'Must specify at least an ID or a name' if names.blank?
    Receptacle.including_samples.where(name: names).tap do |found|
      missing = names - found.map(&:name)
      raise ActiveRecord::RecordNotFound, "Could not find #{name} with names #{missing.inspect}" if missing.present?
    end
  end

  def find_wells_including_samples_for!(details)
    barcodes, well_list = details['barcode'], details['plate well']
    errors.add(:spreadsheet, 'You can only specify one plate per asset group') unless barcodes.uniq.one?
    barcode = barcodes.first
    plate = Plate.find_from_barcode(barcode)
    raise StandardError, "Cannot find plate with barcode #{barcode} for #{details['rows']}" if plate.nil?
    well_locations = well_list.map(&:strip)
    wells = plate.wells.including_samples.located_at(well_locations)
    raise StandardError, "Too few wells found for #{details['rows']}: #{wells.map(&:map).map(&:description).inspect}" if wells.length != well_locations.size
    wells
  end

  def find_tubes_including_samples_for!(details)
    details['barcode'].map do |barcode|
      SBCF::HUMAN_BARCODE_FORMAT.match?(barcode) or raise StandardError, 'Tube Barcode should be human readable (e.g. NT2P)'
      Tube.including_samples.find_from_barcode(barcode) or raise StandardError, "Cannot find tube with barcode #{barcode} for rows #{details['rows']}."
    end
  end
end
