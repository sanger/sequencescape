# This module contains methods associated with the now defunct Illumina-C Generic Lims pipleine.
#
# This module was used to generate the purposes and their associations as part of
# both the seeds and the original migration.
#
# Removal of this code shouldn't affect production, but will disrupt seeds,
# and potentially a number of cucumber features. It will probably also require
# the corresponding search objects to be deprecated.
#
# @todo #2396 Remove
module IlluminaC::PlatePurposes
  PLATE_PURPOSE_FLOWS = [
    [
      'ILC Stock',
      'ILC AL Libs',
      'ILC Lib PCR',
      'ILC Lib PCR-XP',
      'ILC AL Libs Tagged',
      'ILC Lib Chromium'
    ]
  ].freeze

  TUBE_PURPOSE_FLOWS = [
    [
      'ILC Lib Pool Norm'
    ]
  ].freeze

  QC_TUBE_PURPOSE_FLOWS = [].freeze

  QC_TUBE = 'ILC QC Pool'.freeze

  BRANCHES = [
    ['ILC Stock', 'ILC AL Libs', 'ILC Lib PCR', 'ILC Lib PCR-XP', 'ILC Lib Pool Norm'],
    ['ILC Stock', 'ILC AL Libs Tagged', 'ILC Lib Pool Norm'],
    ['ILC Stock', 'ILC Lib Chromium', 'ILC Lib Pool Norm']
  ].freeze

  STOCK_PLATE_PURPOSE = 'ILC Stock'.freeze

  # We Don't have QC Plates
  PLATE_PURPOSE_LEADING_TO_QC_TUBES = [
    'ILC AL Libs Tagged',
    'ILC Lib PCR-XP'
  ].freeze

  STOCK_PLATE_PURPOSE_TO_OUTER_REQUEST = [
    ['ILC Stock', 'illumina_c_pcr'],
    ['ILC Stock', 'illumina_c_nopcr'],
    ['ILC Stock', 'illumina_c_pcr_no_pool'],
    ['ILC Stock', 'illumina_c_no_pcr_no_pool'],
    ['ILC Stock', 'illumina_c_chromium_library']
  ].freeze

  OUTPUT_PLATE_PURPOSES = [].freeze

  PLATE_PURPOSE_TYPE = {
    'ILC QC Pool' => IlluminaC::QcPoolPurpose,
    'ILC Stock' => IlluminaC::StockPurpose,
    'ILC AL Libs' => PlatePurpose::InitialPurpose,
    'ILC Lib PCR' => IlluminaC::LibPcrPurpose,
    'ILC Lib PCR-XP' => IlluminaC::LibPcrXpPurpose,
    'ILC AL Libs Tagged' => IlluminaC::AlLibsTaggedPurpose,
    'ILC Lib Chromium' => IlluminaC::AlLibsTaggedPurpose,
    'ILC Lib Pool Norm' => IlluminaC::MxTubePurpose
  }.freeze

  def self.request_type_prefix
    'Illumina-C'
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
      qc_tube_purpose = purpose_for(self::QC_TUBE).create!(name: self::QC_TUBE, target_type: 'QcTube', barcode_printer_type: BarcodePrinterType1DTube.first)
      self::PLATE_PURPOSE_LEADING_TO_QC_TUBES.each do |name|
        plate_purpose = Purpose.find_by(name: name) or raise StandardError, "Cannot find purpose #{name.inspect}"
        plate_purpose.child_relationships.create!(child: qc_tube_purpose)
      end
    end
  end
end

# We require all the plate and tube purpose files here as Rails eager loading does not play nicely with single table
# inheritance

%w(al_libs_tagged lib_pcr lib_pcr_xp mx_tube qc_pool stock).each do |type|
  require_dependency "app/models/illumina_c/#{type}_purpose"
end
