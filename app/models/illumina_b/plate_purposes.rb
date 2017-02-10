# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2015 Genome Research Ltd.

module IlluminaB::PlatePurposes
  PLATE_PURPOSE_FLOWS = [
    %w(
ILB_STD_INPUT
ILB_STD_COVARIS
ILB_STD_SH
ILB_STD_PREPCR
ILB_STD_PCR
ILB_STD_PCRR
ILB_STD_PCRXP
ILB_STD_PCRRXP
)
  ]

  TUBE_PURPOSE_FLOWS = [
    [
      'ILB_STD_STOCK',
      'ILB_STD_MX'
    ]
  ]

  BRANCHES = [
    %w(ILB_STD_INPUT ILB_STD_COVARIS ILB_STD_SH ILB_STD_PREPCR ILB_STD_PCR ILB_STD_PCRXP ILB_STD_STOCK ILB_STD_MX),
    %w(ILB_STD_PREPCR ILB_STD_PCRR ILB_STD_PCRRXP ILB_STD_STOCK)
  ]

  STOCK_PLATE_PURPOSE = 'ILB_STD_INPUT'

  # Don't have ILllumina B QC plates at the momnet...
  PLATE_PURPOSE_LEADING_TO_QC_PLATES = [
  ]

  STOCK_PLATE_PURPOSE_TO_OUTER_REQUEST = {
    'ILB_STD_INPUT' => 'illumina_b_std'
  }

  OUTPUT_PLATE_PURPOSES = []

  PLATE_PURPOSES_TO_REQUEST_CLASS_NAMES = [
    ['ILB_STD_INPUT',  'ILB_STD_COVARIS', :initial]
  ]

  PLATE_PURPOSE_TYPE = {
    'ILB_STD_INPUT'   => PlatePurpose::Input,
    'ILB_STD_COVARIS' => PlatePurpose::InitialPurpose,
    'ILB_STD_SH'      => PlatePurpose,
    'ILB_STD_PREPCR'  => PlatePurpose,
    'ILB_STD_PCR'     => PlatePurpose,
    'ILB_STD_PCRXP'   => IlluminaHtp::FinalPlatePurpose,
    'ILB_STD_PCRR'    => PlatePurpose,
    'ILB_STD_PCRRXP'  => IlluminaHtp::FinalPlatePurpose,
    'ILB_STD_STOCK'   => IlluminaHtp::StockTubePurpose,
    'ILB_STD_MX'      => IlluminaB::MxTubePurpose
  }

  def self.request_type_prefix
    'Illumina-B'
  end

  extend IlluminaHtp::PlatePurposes::PurposeHelpers
end

# We require all the plate and tube purpose files here as Rails eager loading does not play nicely with single table
# inheritance
require_dependency 'app/models/illumina_b/mx_tube_purpose'
