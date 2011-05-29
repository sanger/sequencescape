# Initially copied from SNP
plate_purposes = <<-EOS
- name: Working Dilution
  qc_display: false
  pulldown_display:
  id: 1
  type: DilutionPlatePurpose
  target_type: WorkingDilutionPlate
- name: Stock Plate
  qc_display: true
  pulldown_display:
  id: 2
  type:
  target_type:
- name: optimisation
  qc_display: false
  pulldown_display:
  id: 3
  type:
  target_type:
- name: 4ng
  qc_display: false
  pulldown_display:
  id: 4
  type:
  target_type:
- name: 8ng
  qc_display: false
  pulldown_display:
  id: 5
  type:
  target_type:
- name: 40ng
  qc_display: false
  pulldown_display:
  id: 6
  type:
  target_type:
- name: Whole Genome Amplification
  qc_display: false
  pulldown_display:
  id: 7
  type:
  target_type:
- name: Perlegen
  qc_display: false
  pulldown_display:
  id: 8
  type:
  target_type:
- name: GoldenGate
  qc_display: false
  pulldown_display:
  id: 9
  type:
  target_type:
- name: Affymetrix
  qc_display: false
  pulldown_display:
  id: 10
  type:
  target_type:
- name: Pre Amplification
  qc_display: false
  pulldown_display:
  id: 11
  type:
  target_type:
- name: 800ng
  qc_display: false
  pulldown_display:
  id: 12
  type:
  target_type:
- name: Sequenom
  qc_display: false
  pulldown_display:
  id: 13
  type: QcPlatePurpose
  target_type:
- name: Gel Dilution
  qc_display: false
  pulldown_display:
  id: 14
  type: WorkingDilutionPlatePurpose
  target_type: GelDilutionPlate
- name: Infinium 15k
  qc_display: false
  pulldown_display:
  id: 15
  type:
  target_type:
- name: Infinium 550k
  qc_display: false
  pulldown_display:
  id: 16
  type:
  target_type:
- name: Infinium 317k
  qc_display: false
  pulldown_display:
  id: 17
  type:
  target_type:
- name: Pico Dilution
  qc_display: false
  pulldown_display:
  id: 18
  type: DilutionPlatePurpose
  target_type: PicoDilutionPlate
- name: Pico Assay A
  qc_display: false
  pulldown_display:
  id: 19
  type: PicoAssayPlatePurpose
  target_type: PicoAssayAPlate
- name: Normalisation
  qc_display: true
  pulldown_display:
  id: 20
  type:
  target_type:
- name: Purification
  qc_display: false
  pulldown_display:
  id: 21
  type:
  target_type:
- name: Infinium 650k
  qc_display: false
  pulldown_display:
  id: 22
  type:
  target_type:
- name: Returned To Supplier
  qc_display: false
  pulldown_display:
  id: 23
  type:
  target_type:
- name: PCR QC Dilution
  qc_display: false
  pulldown_display:
  id: 24
  type:
  target_type:
- name: External
  qc_display: false
  pulldown_display:
  id: 25
  type:
  target_type:
- name: Infinium 370K
  qc_display: false
  pulldown_display:
  id: 26
  type:
  target_type:
- name: Infinium 550k Duo
  qc_display: false
  pulldown_display:
  id: 27
  type:
  target_type:
- name: Cardio_chip
  qc_display: false
  pulldown_display:
  id: 28
  type:
  target_type:
- name: Infinium 1M
  qc_display: false
  pulldown_display:
  id: 29
  type:
  target_type:
- name: CNV
  qc_display: false
  pulldown_display:
  id: 30
  type:
  target_type:
- name: Canine Chip
  qc_display: false
  pulldown_display:
  id: 31
  type:
  target_type:
- name: TaqMan
  qc_display: false
  pulldown_display:
  id: 32
  type:
  target_type:
- name: Solexa_Seq
  qc_display: false
  pulldown_display:
  id: 33
  type:
  target_type:
- name: Illumina-external
  qc_display: false
  pulldown_display:
  id: 34
  type:
  target_type:
- name: CVD55_v2
  qc_display: false
  pulldown_display:
  id: 35
  type:
  target_type:
- name: Infinium_610K
  qc_display: false
  pulldown_display:
  id: 36
  type:
  target_type:
- name: Template
  qc_display: false
  pulldown_display:
  id: 37
  type:
  target_type:
- name: Pico Standard
  qc_display: true
  pulldown_display:
  id: 38
  type:
  target_type:
- name: Affymetrix_SNP6
  qc_display: false
  pulldown_display:
  id: 39
  type:
  target_type:
- name: WTCCC_iSEL
  qc_display: false
  pulldown_display:
  id: 40
  type:
  target_type:
- name: Infinium 670k
  qc_display: false
  pulldown_display:
  id: 41
  type:
  target_type:
- name: Infinium 1.2M
  qc_display: false
  pulldown_display:
  id: 42
  type:
  target_type:
- name: Sty PCR
  qc_display: false
  pulldown_display:
  id: 43
  type:
  target_type:
- name: Nsp PCR
  qc_display: false
  pulldown_display:
  id: 44
  type:
  target_type:
- name: Elution
  qc_display: false
  pulldown_display:
  id: 45
  type:
  target_type:
- name: Frag
  qc_display: false
  pulldown_display:
  id: 46
  type:
  target_type:
- name: Label
  qc_display: false
  pulldown_display:
  id: 47
  type:
  target_type:
- name: Hybridisation
  qc_display: false
  pulldown_display:
  id: 48
  type:
  target_type:
- name: Omnichip
  qc_display: false
  pulldown_display:
  id: 49
  type:
  target_type:
- name: Metabochip
  qc_display: false
  pulldown_display:
  id: 50
  type:
  target_type:
- name: 23andMe
  qc_display: false
  pulldown_display:
  id: 51
  type:
  target_type:
- name: Methylation_27
  qc_display: false
  pulldown_display:
  id: 52
  type:
  target_type:
- name: ImmunoChip
  qc_display: false
  pulldown_display:
  id: 53
  type:
  target_type:
- name: OMNI 1
  qc_display: false
  pulldown_display:
  id: 54
  type:
  target_type:
- name: OMNI EXPRESS
  qc_display: false
  pulldown_display:
  id: 55
  type:
  target_type:
- name: Pulldown
  qc_display: true
  pulldown_display:
  id: 56
  type: PulldownPlatePurpose
  target_type:
- name: Dilution Plates
  qc_display: true
  pulldown_display:
  id: 57
  type: DilutionPlatePurpose
  target_type:
- name: Pico Assay Plates
  qc_display: true
  pulldown_display:
  id: 58
  type: PicoAssayPlatePurpose
  target_type:
- name: Pico Assay B
  qc_display: false
  pulldown_display:
  id: 59
  type: PicoAssayPlatePurpose
  target_type: PicoAssayBPlate
- name: Gel Dilution Plates
  qc_display: true
  pulldown_display:
  id: 60
  type: WorkingDilutionPlatePurpose
  target_type:
- name: Pulldown Aliquot
  qc_display: false
  pulldown_display: true
  id: 74
  type: PulldownAliquotPlatePurpose
  target_type: PulldownAliquotPlate
- name: Sonication
  qc_display: false
  pulldown_display: true
  id: 75
  type: PulldownSonicationPlatePurpose
  target_type: PulldownSonicationPlate
- name: Run of Robot
  qc_display: false
  pulldown_display: true
  id: 76
  type: PulldownRunOfRobotPlatePurpose
  target_type: PulldownRunOfRobotPlate
- name: EnRichment 1
  qc_display: false
  pulldown_display: true
  id: 77
  type: PulldownEnrichmentOnePlatePurpose
  target_type: PulldownEnrichmentOnePlate
- name: EnRichment 2
  qc_display: false
  pulldown_display: true
  id: 78
  type: PulldownEnrichmentTwoPlatePurpose
  target_type: PulldownEnrichmentTwoPlate
- name: EnRichment 3
  qc_display: false
  pulldown_display: true
  id: 79
  type: PulldownEnrichmentThreePlatePurpose
  target_type: PulldownEnrichmentThreePlate
- name: EnRichment 4
  qc_display: false
  pulldown_display: true
  id: 80
  type: PulldownEnrichmentFourPlatePurpose
  target_type: PulldownEnrichmentFourPlate
- name: Sequence Capture
  qc_display: false
  pulldown_display: true
  id: 81
  type: PulldownSequenceCapturePlatePurpose
  target_type: PulldownSequenceCapturePlate
- name: Pulldown PCR
  qc_display: false
  pulldown_display: true
  id: 82
  type: PulldownPcrPlatePurpose
  target_type: PulldownPcrPlate
- name: Pulldown qPCR
  qc_display: false
  pulldown_display: true
  id: 83
  type: PulldownQpcrPlatePurpose
  target_type: PulldownQpcrPlate
  EOS
  
plate_purposes_data = []
YAML::load(plate_purposes).each do |plate_purpose|
  if plate_purpose["type"].blank?
    plate_purposes_data << PlatePurpose.new(plate_purpose)
  else
    plate_purposes_data << eval(plate_purpose["type"]).new(plate_purpose)
  end
end

PlatePurpose.import plate_purposes_data

# Build the links between the parent and child plate purposes
relationships = {
  "Working Dilution"    => ["Working Dilution", "Pico Dilution"],
  "Pico Dilution"       => ["Working Dilution", "Pico Dilution"],
  "Pico Assay A"        => ["Pico Assay A", "Pico Assay B"],
  "Pulldown"            => ["Pulldown Aliquot"],
  "Dilution Plates"     => ["Working Dilution", "Pico Dilution"],
  "Pico Assay Plates"   => ["Pico Assay A", "Pico Assay B"],
  "Pico Assay B"        => ["Pico Assay A", "Pico Assay B"],
  "Gel Dilution Plates" => ["Gel Dilution"],
  "Pulldown Aliquot"    => ["Sonication"],
  "Sonication"          => ["Run of Robot"],
  "Run of Robot"        => ["EnRichment 1"],
  "EnRichment 1"        => ["EnRichment 2"],
  "EnRichment 2"        => ["EnRichment 3"],
  "EnRichment 3"        => ["EnRichment 4"],
  "EnRichment 4"        => ["Sequence Capture"],
  "Sequence Capture"    => ["Pulldown PCR"],
  "Pulldown PCR"        => ["Pulldown qPCR"]
}

PULLDOWN_PLATE_PURPOSE_FLOWS = [
  [
    'WGS fragmentation plate',
    'WGS fragment purification plate',
    'WGS library preparation plate',
    'WGS library plate',
    'WGS library PCR plate',
    'WGS amplified library plate',
    'WGS pooled amplified library plate'
  ], [
    'SC fragmentation plate',
    'SC fragment purification plate',
    'SC library preparation plate',
    'SC library plate',
    'SC library PCR plate',
    'SC amplified library plate',
    'SC hybridisation plate',
    'SC captured library plate',
    'SC captured library PCR plate',
    'SC amplified captured library plate',
    'SC pooled captured library plate'
  ], [
    'ISC fragmentation plate',
    'ISC fragment purification plate',
    'ISC library preparation plate',
    'ISC library plate',
    'ISC library PCR plate',
    'ISC amplified library plate',
    'ISC pooled amplified library plate',
    'ISC hybridisation plate',
    'ISC captured library plate',
    'ISC captured library PCR plate',
    'ISC amplified captured library plate',
    'ISC pooled captured library plate'
  ]
]

PULLDOWN_PLATE_PURPOSE_LEADING_TO_QC_PLATES = [
  'WGS fragment purification plate',
  'WGS library preparation plate',
  'WGS amplified library plate',

  'SC fragment purification plate',
  'SC library preparation plate',
  'SC amplified library plate',
  'SC amplified captured library plate',

  'ISC fragment purification plate',
  'ISC library preparation plate',
  'ISC amplified library plate',
  'ISC amplified captured library plate'
]

ActiveRecord::Base.transaction do
  # All of the PlatePurpose names specified in the keys of RELATIONSHIPS have complicated relationships.
  # The others are simply maps to themselves.
  PlatePurpose.all(:conditions => [ 'name NOT IN (?)', relationships.keys ]).each do |purpose|
    purpose.child_relationships.create!(:child => purpose)
  end

  # Here are the complicated ones:
  PlatePurpose.all(:conditions => { :name => relationships.keys }).each do |purpose|
    PlatePurpose.all(:conditions => { :name => relationships[purpose.name] }).each do |child|
      purpose.child_relationships.create!(:child => child)
    end
  end

  # And here is pulldown
  stock_plate_purpose = PlatePurpose.create!(:name => 'Pulldown stock plate')
  PULLDOWN_PLATE_PURPOSE_FLOWS.each do |flow|
    initial_purpose = stock_plate_purpose.child_plate_purposes.create!(:type => 'InitialPulldownPlatePurpose', :name => flow.shift)
    flow.inject(initial_purpose) do |parent, child_plate_name|
      parent.child_plate_purposes.create!(:name => child_plate_name)
    end
  end

  qc_plate_purpose = PlatePurpose.create!(:name => 'Pulldown QC plate')

  PULLDOWN_PLATE_PURPOSE_LEADING_TO_QC_PLATES.each do |name|
    plate_purpose = PlatePurpose.find_by_name(name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
    plate_purpose.child_plate_purposes << qc_plate_purpose
  end
end
