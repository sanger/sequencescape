module IlluminaC::PlatePurposes
  PLATE_PURPOSE_FLOWS = [
    [
      'ILC Stock',
      'ILC AL Libs',
      'ILC Lib PCR',
      'ILC Lib PCR-XP',
      'ILC AL Libs Tagged'
    ]
  ]

  TUBE_PURPOSE_FLOWS = [
    [
      'ILC Lib Pool Norm'
    ]
  ]

  QC_TUBE = 'ILC QC Pool'

  BRANCHES = [
    ['ILC Stock','ILC AL Libs','ILC Lib PCR','ILC Lib PCR-XP','ILC Lib Pool Norm'],
    ['ILC Stock','ILC AL Libs Tagged','ILC Lib Pool Norm']
  ]

  STOCK_PLATE_PURPOSE = 'ILC Stock'

  # We Don't have QC Plates
  PLATE_PURPOSE_LEADING_TO_QC_TUBES = [
    'ILC AL Libs Tagged',
    'ILC Lib PCR-XP'
  ]

  STOCK_PLATE_PURPOSE_TO_OUTER_REQUEST = {
    'ILC Stock'  => 'illumina_c_pcr',
    'ILC Stock'  => 'illumina_c_nopcr'

  }

  OUTPUT_PLATE_PURPOSES = []

  PLATE_PURPOSES_TO_REQUEST_CLASS_NAMES = [
    [ 'ILC Stock',   'ILC AL Libs',        'IlluminaC::Requests::InitialTransfer' ],
    [ 'ILC Stock',   'ILC AL Libs Tagged', 'IlluminaC::Requests::StockToAlLibsTagged' ],
    [ 'ILC Lib PCR', 'ILC Lib PCR-XP',     'IlluminaC::Requests::QcCompleteable'  ]
  ]

  PLATE_PURPOSE_TYPE = {
    'ILC QC Pool'        => IlluminaC::QcPoolPurpose,
    'ILC Stock'          => IlluminaC::StockPurpose,
    'ILC AL Libs'        => IlluminaC::AlLibsPurpose,
    'ILC Lib PCR'        => IlluminaC::LibPcrPurpose,
    'ILC Lib PCR-XP'     => IlluminaC::LibPcrXpPurpose,
    'ILC AL Libs Tagged' => IlluminaC::AlLibsTaggedPurpose,
    'ILC Lib Pool Norm'  => IlluminaC::MxTubePurpose
  }

  def self.request_type_prefix
    "Illumina-C"
  end

  extend IlluminaHtp::PlatePurposes::PurposeHelpers

  def self.create_qc_plates
    nil
  end

  def self.create_tube_purposes
    super
    create_qc_tubes
  end

  def self.create_qc_tubes
    ActiveRecord::Base.transaction do
      qc_tube_purpose = purpose_for(self::QC_TUBE).create!(:name=>self::QC_TUBE, :target_type=>'QcTube',:barcode_printer_type => BarcodePrinterType.find_by_type('BarcodePrinterType1DTube'))
      self::PLATE_PURPOSE_LEADING_TO_QC_TUBES.each do |name|
        plate_purpose = Purpose.find_by_name(name) or raise StandardError, "Cannot find purpose #{name.inspect}"
        plate_purpose.child_relationships.create!(:child => qc_tube_purpose, :transfer_request_type => RequestType.find_by_name('Transfer'))
      end
    end
  end

end
