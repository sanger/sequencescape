# frozen_string_literal: true

# Extracted from {Plate} Used to convert a plate to {SampleTube}
class Plate::SampleTubeFactory < SimpleDelegator
  def create_sample_tubes
    wells.map { |well| create_child_sample_tube(well) }
  end

  def create_child_sample_tube(well)
    Tube::Purpose.standard_sample_tube.create!.tap do |sample_tube|
      sample_tube.receptacle.transfer_requests_as_target.create!(asset: well)
    end
  end

  def create_sample_tubes_and_print_barcodes(barcode_printer)
    sample_tubes = create_sample_tubes
    print_job = LabelPrinter::PrintJob.new(barcode_printer.name, LabelPrinter::Label::PlateToTubes, sample_tubes:)
    print_job.execute

    sample_tubes
  end

  # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
  def self.create_sample_tubes_asset_group_and_print_barcodes(plates, barcode_printer, study)
    return nil if plates.empty?

    plate_barcodes = plates.map(&:barcode_number)
    asset_group =
      AssetGroup.find_or_create_asset_group("#{plate_barcodes.join('-')} #{Time.current.to_fs(:sortable)} ", study)
    plates.each do |plate|
      factory = Plate::SampleTubeFactory.new(plate)
      next if factory.wells.empty?

      asset_group.assets << factory.create_sample_tubes_and_print_barcodes(barcode_printer).map(&:receptacle)
    end

    return nil if asset_group.assets.empty?

    asset_group.save!

    asset_group
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
