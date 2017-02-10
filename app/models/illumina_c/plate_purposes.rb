# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015,2016 Genome Research Ltd.

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
  ]

  TUBE_PURPOSE_FLOWS = [
    [
      'ILC Lib Pool Norm'
    ]
  ]

  QC_TUBE = 'ILC QC Pool'

  BRANCHES = [
    ['ILC Stock', 'ILC AL Libs', 'ILC Lib PCR', 'ILC Lib PCR-XP', 'ILC Lib Pool Norm'],
    ['ILC Stock', 'ILC AL Libs Tagged', 'ILC Lib Pool Norm'],
    ['ILC Stock', 'ILC Lib Chromium', 'ILC Lib Pool Norm'],
  ]

  STOCK_PLATE_PURPOSE = 'ILC Stock'

  # We Don't have QC Plates
  PLATE_PURPOSE_LEADING_TO_QC_TUBES = [
    'ILC AL Libs Tagged',
    'ILC Lib PCR-XP'
  ]

  STOCK_PLATE_PURPOSE_TO_OUTER_REQUEST = [
    ['ILC Stock', 'illumina_c_pcr'],
    ['ILC Stock', 'illumina_c_nopcr'],
    ['ILC Stock', 'illumina_c_pcr_no_pool'],
    ['ILC Stock', 'illumina_c_no_pcr_no_pool'],
    ['ILC Stock', 'illumina_c_chromium_library']
  ]

  OUTPUT_PLATE_PURPOSES = []

  PLATE_PURPOSES_TO_REQUEST_CLASS_NAMES = [
    ['ILC Stock', 'ILC AL Libs',        :initial],
    ['ILC Stock', 'ILC AL Libs Tagged', :initial],
    ['ILC Stock', 'ILC Lib Chromium',   :initial]
  ]

  PLATE_PURPOSE_TYPE = {
    'ILC QC Pool'        => IlluminaC::QcPoolPurpose,
    'ILC Stock'          => IlluminaC::StockPurpose,
    'ILC AL Libs'        => PlatePurpose::InitialPurpose,
    'ILC Lib PCR'        => IlluminaC::LibPcrPurpose,
    'ILC Lib PCR-XP'     => IlluminaC::LibPcrXpPurpose,
    'ILC AL Libs Tagged' => IlluminaC::AlLibsTaggedPurpose,
    'ILC Lib Chromium'   => IlluminaC::AlLibsTaggedPurpose,
    'ILC Lib Pool Norm'  => IlluminaC::MxTubePurpose
  }

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
      qc_tube_purpose = purpose_for(self::QC_TUBE).create!(name: self::QC_TUBE, target_type: 'QcTube', barcode_printer_type: BarcodePrinterType.find_by(type: 'BarcodePrinterType1DTube'))
      self::PLATE_PURPOSE_LEADING_TO_QC_TUBES.each do |name|
        plate_purpose = Purpose.find_by(name: name) or raise StandardError, "Cannot find purpose #{name.inspect}"
        plate_purpose.child_relationships.create!(child: qc_tube_purpose, transfer_request_type: RequestType.find_by(name: 'Transfer'))
      end
    end
  end
end

# We require all the plate and tube purpose files here as Rails eager loading does not play nicely with single table
# inheritance

%w(al_libs_tagged lib_pcr lib_pcr_xp mx_tube qc_pool stock).each do |type|
  require_dependency "app/models/illumina_c/#{type}_purpose"
end
