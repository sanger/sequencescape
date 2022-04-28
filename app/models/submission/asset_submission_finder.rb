# frozen_string_literal: true
module Submission::AssetSubmissionFinder # rubocop:todo Style/Documentation
  def is_plate?(details)
    details['barcode'].present? && details['plate well'].present?
  end

  def is_tube?(details)
    details['barcode'].present? && details['plate well'].blank?
  end

  def find_all_assets_by_name_including_samples!(names)
    Receptacle
      .for_bulk_submission
      .named(names)
      .tap do |found|
        missing = names - found.map(&:name)
        raise ActiveRecord::RecordNotFound, "Could not find Labware with names #{missing.inspect}" if missing.present?
      end
  end

  # rubocop:todo Metrics/MethodLength
  def find_wells_including_samples_for!(details) # rubocop:todo Metrics/AbcSize
    barcodes, well_list = details['barcode'], details['plate well']
    errors.add(:spreadsheet, 'You can only specify one plate per asset group') unless barcodes.uniq.one?
    barcode = barcodes.first
    plate = Plate.find_from_barcode(barcode)
    raise StandardError, "Cannot find plate with barcode #{barcode} for #{details['rows']}" if plate.nil?

    well_locations = well_list.map(&:strip)
    wells = plate.wells.for_bulk_submission.located_at(well_locations)
    if wells.length != well_locations.size
      raise StandardError, "Too few wells found for #{details['rows']}: #{wells.map(&:map).map(&:description).inspect}"
    end

    wells
  end

  # rubocop:enable Metrics/MethodLength

  def find_tubes_including_samples_for!(details)
    Receptacle
      .on_a(Tube)
      .for_bulk_submission
      .with_barcode(details['barcode'])
      .tap do |found|
        missing = details['barcode'].reject { |barcode| found.any? { |tube| tube.any_barcode_matching?(barcode) } }
        raise ActiveRecord::RecordNotFound, "Could not find Tubes with barcodes #{missing.inspect}" if missing.present?
      end
  end
end
