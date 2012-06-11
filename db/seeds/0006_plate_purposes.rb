# Initially copied from SNP
plate_purposes = <<-EOS
- name: Working Dilution
  qc_display: false
  id: 1
  type: DilutionPlatePurpose
  target_type: WorkingDilutionPlate
  cherrypickable_target: true
- name: Stock Plate
  qc_display: true
  id: 2
  can_be_considered_a_stock_plate: true
  cherrypickable_target: true
- name: optimisation
  qc_display: false
  id: 3
- name: 4ng
  qc_display: false
  id: 4
- name: 8ng
  qc_display: false
  id: 5
- name: 40ng
  qc_display: false
  id: 6
- name: Whole Genome Amplification
  qc_display: false
  id: 7
  cherrypickable_target: true
- name: Perlegen
  qc_display: false
  id: 8
- name: GoldenGate
  qc_display: false
  id: 9
- name: Affymetrix
  qc_display: false
  id: 10
- name: Pre Amplification
  qc_display: false
  id: 11
- name: 800ng
  qc_display: false
  id: 12
- name: Sequenom
  qc_display: false
  id: 13
  type: QcPlatePurpose
- name: Gel Dilution
  qc_display: false
  id: 14
  type: WorkingDilutionPlatePurpose
  target_type: GelDilutionPlate
- name: Infinium 15k
  qc_display: false
  id: 15
- name: Infinium 550k
  qc_display: false
  id: 16
- name: Infinium 317k
  qc_display: false
  id: 17
- name: Pico Dilution
  qc_display: false
  id: 18
  type: DilutionPlatePurpose
  target_type: PicoDilutionPlate
- name: Pico Assay A
  qc_display: false
  id: 19
  type: PicoAssayPlatePurpose
  target_type: PicoAssayAPlate
- name: Normalisation
  qc_display: true
  id: 20
  cherrypickable_target: true
- name: Purification
  qc_display: false
  id: 21
- name: Infinium 650k
  qc_display: false
  id: 22
- name: Returned To Supplier
  qc_display: false
  id: 23
  cherrypickable_target: true
- name: PCR QC Dilution
  qc_display: false
  id: 24
- name: External
  qc_display: false
  id: 25
- name: Infinium 370K
  qc_display: false
  id: 26
- name: Infinium 550k Duo
  qc_display: false
  id: 27
- name: Cardio_chip
  qc_display: false
  id: 28
- name: Infinium 1M
  qc_display: false
  id: 29
- name: CNV
  qc_display: false
  id: 30
- name: Canine Chip
  qc_display: false
  id: 31
- name: TaqMan
  qc_display: false
  id: 32
- name: Solexa_Seq
  qc_display: false
  id: 33
- name: Illumina-external
  qc_display: false
  id: 34
- name: CVD55_v2
  qc_display: false
  id: 35
- name: Infinium_610K
  qc_display: false
  id: 36
  cherrypickable_target: true
- name: Template
  qc_display: false
  id: 37
- name: Pico Standard
  qc_display: true
  id: 38
- name: Affymetrix_SNP6
  qc_display: false
  id: 39
  cherrypickable_target: true
- name: WTCCC_iSEL
  qc_display: false
  id: 40
- name: Infinium 670k
  qc_display: false
  id: 41
  cherrypickable_target: true
- name: Infinium 1.2M
  qc_display: false
  id: 42
- name: Sty PCR
  qc_display: false
  id: 43
- name: Nsp PCR
  qc_display: false
  id: 44
- name: Elution
  qc_display: false
  id: 45
- name: Frag
  qc_display: false
  id: 46
- name: Label
  qc_display: false
  id: 47
- name: Hybridisation
  qc_display: false
  id: 48
- name: Omnichip
  qc_display: false
  id: 49
  cherrypickable_target: true
- name: Metabochip
  qc_display: false
  id: 50
- name: 23andMe
  qc_display: false
  id: 51
- name: Methylation_27
  qc_display: false
  id: 52
- name: ImmunoChip
  qc_display: false
  id: 53
  cherrypickable_target: true
- name: OMNI 1
  qc_display: false
  id: 54
  cherrypickable_target: true
- name: OMNI EXPRESS
  qc_display: false
  id: 55
  cherrypickable_target: true
- name: Pulldown
  qc_display: true
  id: 56
  type: PulldownPlatePurpose
  cherrypickable_target: true
- name: Dilution Plates
  qc_display: true
  id: 57
  type: DilutionPlatePurpose
- name: Pico Assay Plates
  qc_display: true
  id: 58
  type: PicoAssayPlatePurpose
- name: Pico Assay B
  qc_display: false
  id: 59
  type: PicoAssayPlatePurpose
  target_type: PicoAssayBPlate
- name: Gel Dilution Plates
  qc_display: true
  id: 60
  type: WorkingDilutionPlatePurpose
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
  cherrypickable_target: true
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
  attributes = plate_purpose.reverse_merge('type' => 'PlatePurpose', 'cherrypickable_target' => false)
  plate_purposes_data << attributes.delete('type').constantize.new(attributes)
end

PlatePurpose.import plate_purposes_data

# Some plate purposes that appear to be used by SLF but are not in the seeds from SNP.
(1..5).each do |index|
  PlatePurpose.create!(:name => "Aliquot #{index}", :qc_display => true, :can_be_considered_a_stock_plate => true, :cherrypickable_target => true)
end

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

  # A couple of legacy pulldown types
  PlatePurpose.create!(:name => 'SEQCAP WG', :cherrypickable_target => false)  # Superceded by Pulldown WGS below (here for transition period)
  PlatePurpose.create!(:name => 'SEQCAP SC', :cherrypickable_target => false)  # Superceded by Pulldown SC/ISC below (here for transition period)

  # And here is pulldown
  Pulldown::PlatePurposes::PLATE_PURPOSE_FLOWS.each do |flow|
    # We're using a different plate purpose for each pipeline, which means we need to attach that plate purpose to the request
    # type for it.  Then in the cherrypicking they'll only be able to pick the correct type from the list.
    stock_plate_purpose = Pulldown::StockPlatePurpose.create!(:name => flow.shift, :default_state => 'passed', :can_be_considered_a_stock_plate => true)
    pipeline_name       = /^([^\s]+)/.match(stock_plate_purpose.name)[1]  # Hack but works!
    request_type        = RequestType.find_by_name("Pulldown #{pipeline_name}") or raise StandardError, "Cannot find pulldown pipeline for #{pipeline_name}"
    request_type.acceptable_plate_purposes << stock_plate_purpose

    # Now we can build from the stock plate through to the end
    initial_purpose = stock_plate_purpose.child_plate_purposes.create!(:type => 'Pulldown::InitialPlatePurpose', :name => flow.shift)
    flow.inject(initial_purpose) do |parent, child_plate_name|
      options = { :name => child_plate_name, :cherrypickable_target => false }
      options[:type] = 'Pulldown::LibraryPlatePurpose' if child_plate_name =~ /^(WGS|SC|ISC) library plate$/
      parent.child_plate_purposes.create!(options)
    end
  end

  qc_plate_purpose = PlatePurpose.create!(:name => 'Pulldown QC plate')

  Pulldown::PlatePurposes::PLATE_PURPOSE_LEADING_TO_QC_PLATES.each do |name|
    plate_purpose = PlatePurpose.find_by_name(name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
    plate_purpose.child_plate_purposes << qc_plate_purpose
  end

  # We only have one flow at the moment
  IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS.each do |flow|

    stock_plate = IlluminaB::PlatePurposes.stock_plate_class.create!(
      :name => flow.shift,
      :can_be_considered_a_stock_plate => true,
      :default_state => 'passed',
      :cherrypickable_target => true,
      :cherrypick_direction => IlluminaB::PlatePurposes.plate_direction
      )

    IlluminaB::PlatePurposes.request_type_for(stock_plate).acceptable_plate_purposes  << stock_plate

    flow.inject(stock_plate) do |previous,plate_purpose_name|
      new_purpose = IlluminaB::PlatePurposes::PLATE_PURPOSE_TYPE[plate_purpose_name].create!(
        :name => plate_purpose_name,
        :cherrypickable_target => false,
        :cherrypick_direction => IlluminaB::PlatePurposes.plate_direction
        )
      previous.child_plate_purposes << new_purpose
      new_purpose
    end
  end

end
