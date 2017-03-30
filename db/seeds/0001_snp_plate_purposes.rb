# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2014,2015,2016 Genome Research Ltd.

# Initially copied from SNP
plate_purposes = <<-EOS
- name: Working Dilution
  id: 1
  type: DilutionPlatePurpose
  target_type: WorkingDilutionPlate
  cherrypickable_target: true
  stock_plate: false
- name: Stock Plate
  id: 2
  stock_plate: true
  cherrypickable_target: true
- name: optimisation
  id: 3
- name: 4ng
  id: 4
- name: 8ng
  id: 5
- name: 40ng
  id: 6
- name: Whole Genome Amplification
  id: 7
  cherrypickable_target: true
- name: Perlegen
  id: 8
- name: GoldenGate
  id: 9
- name: Affymetrix
  id: 10
- name: Pre Amplification
  id: 11
- name: 800ng
  id: 12
- name: Sequenom
  id: 13
  type: PlatePurpose
  size: 384
- name: Gel Dilution
  id: 14
  type: PlatePurpose
  target_type: GelDilutionPlate
- name: Infinium 15k
  id: 15
- name: Infinium 550k
  id: 16
- name: Infinium 317k
  id: 17
- name: Pico Dilution
  id: 18
  type: DilutionPlatePurpose
  target_type: PicoDilutionPlate
- name: Pico Assay A
  id: 19
  type: PlatePurpose
  target_type: PicoAssayAPlate
- name: Normalisation
  id: 20
  cherrypickable_target: true
- name: Purification
  id: 21
- name: Infinium 650k
  id: 22
- name: Returned To Supplier
  id: 23
  cherrypickable_target: true
- name: PCR QC Dilution
  id: 24
- name: External
  id: 25
- name: Infinium 370K
  id: 26
- name: Infinium 550k Duo
  id: 27
- name: Cardio_chip
  id: 28
- name: Infinium 1M
  id: 29
- name: CNV
  id: 30
- name: Canine Chip
  id: 31
- name: TaqMan
  id: 32
- name: Solexa_Seq
  id: 33
- name: Illumina-external
  id: 34
- name: CVD55_v2
  id: 35
- name: Infinium_610K
  id: 36
  cherrypickable_target: true
- name: Template
  id: 37
- name: Pico Standard
  id: 38
- name: Affymetrix_SNP6
  id: 39
  cherrypickable_target: true
- name: WTCCC_iSEL
  id: 40
- name: Infinium 670k
  id: 41
  cherrypickable_target: true
- name: Infinium 1.2M
  id: 42
- name: Sty PCR
  id: 43
- name: Nsp PCR
  id: 44
- name: Elution
  id: 45
- name: Frag
  id: 46
- name: Label
  id: 47
- name: Hybridisation
  id: 48
- name: Omnichip
  id: 49
  cherrypickable_target: true
- name: Metabochip
  id: 50
- name: 23andMe
  id: 51
- name: Methylation_27
  id: 52
- name: ImmunoChip
  id: 53
  cherrypickable_target: true
- name: OMNI 1
  id: 54
  cherrypickable_target: true
- name: OMNI EXPRESS
  id: 55
  cherrypickable_target: true
- name: Pulldown
  id: 56
  type: PlatePurpose
  cherrypickable_target: true
- name: Dilution Plates
  id: 57
  type: DilutionPlatePurpose
- name: Pico Assay Plates
  id: 58
  type: PlatePurpose
- name: Pico Assay B
  id: 59
  type: PlatePurpose
  target_type: PicoAssayBPlate
- name: Gel Dilution Plates
  id: 60
  type: PlatePurpose
- name: Pulldown Aliquot
  id: 74
  type: PlatePurpose
  target_type: PulldownAliquotPlate
- name: Sonication
  id: 75
  type: PlatePurpose
  target_type: PulldownSonicationPlate
- name: Run of Robot
  id: 76
  type: PlatePurpose
  target_type: PulldownRunOfRobotPlate
- name: EnRichment 1
  id: 77
  type: PlatePurpose
  target_type: PulldownEnrichmentOnePlate
- name: EnRichment 2
  id: 78
  type: PlatePurpose
  target_type: PulldownEnrichmentTwoPlate
- name: EnRichment 3
  id: 79
  type: PlatePurpose
  target_type: PulldownEnrichmentThreePlate
- name: EnRichment 4
  id: 80
  type: PlatePurpose
  target_type: PulldownEnrichmentFourPlate
- name: Sequence Capture
  id: 81
  type: PlatePurpose
  target_type: PulldownSequenceCapturePlate
  cherrypickable_target: true
- name: Pulldown PCR
  id: 82
  type: PlatePurpose
  target_type: PulldownPcrPlate
- name: Pulldown qPCR
  id: 83
  type: PlatePurpose
  target_type: PulldownQpcrPlate
- name: Pre-Extracted Plate
  id: 84
  type: PlatePurpose
  target_type: Plate
  stock_plate: true
EOS

AssetShape.create!(
  name: 'Standard',
  horizontal_ratio: 3,
  vertical_ratio: 2,
  description_strategy: 'Map::Coordinate'
)
AssetShape.create!(
  name: 'Fluidigm96',
  horizontal_ratio: 3,
  vertical_ratio: 8,
  description_strategy: 'Map::Sequential'
)
AssetShape.create!(
  name: 'Fluidigm192',
  horizontal_ratio: 3,
  vertical_ratio: 4,
  description_strategy: 'Map::Sequential'
)
AssetShape.create!(
  name: 'StripTubeColumn',
  horizontal_ratio: 1,
  vertical_ratio: 8,
  description_strategy: 'Map::Sequential'
)

YAML::load(plate_purposes).each do |plate_purpose|
  attributes = plate_purpose.reverse_merge(
    'type' => 'PlatePurpose',
    'cherrypickable_target' => false,
    'asset_shape_id' => AssetShape.find_by(name: 'Standard').id
  )
  attributes.delete('type').constantize.new(attributes) do |purpose|
    purpose.id = attributes['id']
  end.save!
end

# Some plate purposes that appear to be used by SLF but are not in the seeds from SNP.
5.times do |index|
  PlatePurpose.create!(name: "Aliquot #{index}", stock_plate: true, cherrypickable_target: true)
end
PlatePurpose.create!(name: 'ABgene_0765', stock_plate: false, cherrypickable_source: true, cherrypickable_target: false)
PlatePurpose.create!(name: 'ABgene_0800', stock_plate: false, cherrypickable_source: true, cherrypickable_target: true)
PlatePurpose.create!(name: 'FluidX075', stock_plate: false, cherrypickable_source: true, cherrypickable_target: false)

# Build the links between the parent and child plate purposes
relationships = {
  'Working Dilution'    => ['Working Dilution', 'Pico Dilution'],
  'Pico Dilution'       => ['Working Dilution', 'Pico Dilution'],
  'Pico Assay A'        => ['Pico Assay A', 'Pico Assay B'],
  'Pulldown'            => ['Pulldown Aliquot'],
  'Dilution Plates'     => ['Working Dilution', 'Pico Dilution'],
  'Pico Assay Plates'   => ['Pico Assay A', 'Pico Assay B'],
  'Pico Assay B'        => ['Pico Assay A', 'Pico Assay B'],
  'Gel Dilution Plates' => ['Gel Dilution'],
  'Pulldown Aliquot'    => ['Sonication'],
  'Sonication'          => ['Run of Robot'],
  'Run of Robot'        => ['EnRichment 1'],
  'EnRichment 1'        => ['EnRichment 2'],
  'EnRichment 2'        => ['EnRichment 3'],
  'EnRichment 3'        => ['EnRichment 4'],
  'EnRichment 4'        => ['Sequence Capture'],
  'Sequence Capture'    => ['Pulldown PCR'],
  'Pulldown PCR'        => ['Pulldown qPCR']
}

ActiveRecord::Base.transaction do
  # All of the PlatePurpose names specified in the keys of RELATIONSHIPS have complicated relationships.
  # The others are simply maps to themselves.
  PlatePurpose.where(['name NOT IN (?)', relationships.keys]).each do |purpose|
    purpose.child_relationships.create!(child: purpose, transfer_request_type: RequestType.transfer)
  end

  # Here are the complicated ones:
  PlatePurpose.where(name: relationships.keys).each do |purpose|
    PlatePurpose.where(name: relationships[purpose.name]).each do |child|
      purpose.child_relationships.create!(child: child, transfer_request_type: RequestType.transfer)
    end
  end

  # A couple of legacy pulldown types
  PlatePurpose.create!(name: 'SEQCAP WG', cherrypickable_target: false)  # Superceded by Pulldown WGS below (here for transition period)
  PlatePurpose.create!(name: 'SEQCAP SC', cherrypickable_target: false)  # Superceded by Pulldown SC/ISC below (here for transition period)

  PlatePurpose.create!(
  name: 'STA',
  default_state: 'pending',
  barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
  cherrypickable_target: true,
  cherrypick_direction: 'column',
  asset_shape: AssetShape.find_by(name: 'Standard')
)
PlatePurpose.create!(
  name: 'STA2',
  default_state: 'pending',
  barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
  cherrypickable_target: true,
  cherrypick_direction: 'column',
  asset_shape: AssetShape.find_by(name: 'Standard')
)
PlatePurpose.create!(
  name: 'SNP Type',
  default_state: 'pending',
  barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
  cherrypickable_target: true,
  cherrypick_direction: 'column',
  asset_shape: AssetShape.find_by(name: 'Standard')
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
  cherrypickable_source: false,
  size: 96,
  asset_shape: AssetShape.find_by(name: 'Standard'),
  barcode_for_tecan: 'ean13_barcode'
)
