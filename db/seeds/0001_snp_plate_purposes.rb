# frozen_string_literal: true

# Initially copied from SNP
plate_purposes = <<~EOS
  - name: Working Dilution
    type: DilutionPlatePurpose
    target_type: WorkingDilutionPlate
    cherrypickable_target: true
    stock_plate: false
    prefix: WD
  - name: 40ng
  - name: Whole Genome Amplification
    cherrypickable_target: true
  - name: Sequenom
    size: 384
  - name: Gel Dilution
    target_type: GelDilutionPlate
    prefix: GD
  - name: Pico Dilution
    type: DilutionPlatePurpose
    prefix: PD
    target_type: PicoDilutionPlate
  - name: Pico Assay A
    target_type: Plate
    prefix: PA
  - name: Infinium_610K
    cherrypickable_target: true
  - name: Pico Standard
  - name: Affymetrix_SNP6
    cherrypickable_target: true
  - name: Infinium 670k
    cherrypickable_target: true
  - name: Methylation_27
  - name: ImmunoChip
    cherrypickable_target: true
  - name: OMNI 1
    cherrypickable_target: true
  - name: OMNI EXPRESS
    cherrypickable_target: true
  - name: Pulldown
    cherrypickable_target: true
  - name: Dilution Plates
    type: DilutionPlatePurpose
  - name: Pico Assay Plates
  - name: Pico Assay B
    target_type: Plate
    prefix: PB
  - name: Gel Dilution Plates
  - name: Pulldown Aliquot
    prefix: FA
EOS

YAML
  .load(plate_purposes)
  .each do |plate_purpose|
    attributes =
      plate_purpose.reverse_merge(
        'type' => 'PlatePurpose',
        'cherrypickable_target' => false,
        'asset_shape_id' => AssetShape.default_id,
        'prefix' => 'DN',
        'target_type' => 'Plate'
      )
    attributes.delete('type').constantize.new(attributes) { |purpose| purpose.id = attributes['id'] }.save!
  end

# Some plate purposes that appear to be used by SLF but are not in the seeds from SNP.
5.times { |index| PlatePurpose.create!(name: "Aliquot #{index}", stock_plate: true, cherrypickable_target: true) }

ActiveRecord::Base.transaction do
  # A couple of legacy pulldown types
  # Superceded by Pulldown WGS below (here for transition period)
  PlatePurpose.create!(name: 'SEQCAP WG', cherrypickable_target: false)

  # Superceded by Pulldown SC/ISC below (here for transition period)
  PlatePurpose.create!(name: 'SEQCAP SC', cherrypickable_target: false)

  PlatePurpose.create!(
    name: 'STA',
    default_state: 'pending',
    barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
    cherrypickable_target: true,
    cherrypick_direction: 'column',
    asset_shape_id: AssetShape.default_id
  )
  PlatePurpose.create!(
    name: 'STA2',
    default_state: 'pending',
    barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
    cherrypickable_target: true,
    cherrypick_direction: 'column',
    asset_shape_id: AssetShape.default_id
  )
  PlatePurpose.create!(
    name: 'SNP Type',
    default_state: 'pending',
    barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
    cherrypickable_target: true,
    cherrypick_direction: 'column',
    asset_shape_id: AssetShape.default_id
  )
  PlatePurpose.create!(
    name: 'Fluidigm 96-96',
    default_state: 'pending',
    cherrypickable_target: true,
    cherrypick_direction: 'interlaced_column',
    size: 96,
    asset_shape: AssetShape.find_by(name: 'Fluidigm96')
  )
  PlatePurpose.create!(
    name: 'Fluidigm 192-24',
    default_state: 'pending',
    cherrypickable_target: true,
    cherrypick_direction: 'interlaced_column',
    size: 192,
    asset_shape: AssetShape.find_by(name: 'Fluidigm192')
  )
end
PlatePurpose.create!(
  name: 'PacBio Sheared',
  target_type: 'Plate',
  default_state: 'pending',
  barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
  cherrypickable_target: false,
  size: 96,
  asset_shape_id: AssetShape.default_id
)
MessengerCreator.create!(
  purpose: Purpose.find_by(name: 'Stock Plate'),
  root: 'stock_resource',
  template: 'WellStockResourceIo',
  target_finder_class: 'WellFinder'
)
