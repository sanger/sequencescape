#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013 Genome Research Ltd.

module IlluminaB::PlatePurposes
  PLATE_PURPOSE_FLOWS = [
    [
      'ILB_STD_INPUT',
      'ILB_STD_COVARIS',
      'ILB_STD_SH',
      'ILB_STD_PREPCR',
      'ILB_STD_PCR',
      'ILB_STD_PCRR',
      'ILB_STD_PCRXP',
      'ILB_STD_PCRRXP'
    ]
  ]

  TUBE_PURPOSE_FLOWS = [
    [
      'ILB_STD_STOCK',
      'ILB_STD_MX'
    ]
  ]

  BRANCHES = [
    [ 'ILB_STD_INPUT', 'ILB_STD_COVARIS', 'ILB_STD_SH', 'ILB_STD_PREPCR', 'ILB_STD_PCR', 'ILB_STD_PCRXP', 'ILB_STD_STOCK', 'ILB_STD_MX' ],
    [ 'ILB_STD_PREPCR', 'ILB_STD_PCRR', 'ILB_STD_PCRRXP', 'ILB_STD_STOCK' ]
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
    [ 'ILB_STD_INPUT',   'ILB_STD_COVARIS','IlluminaB::Requests::InputToCovaris'   ],
    [ 'ILB_STD_COVARIS', 'ILB_STD_SH',     'IlluminaB::Requests::CovarisToSheared' ],
    [ 'ILB_STD_PREPCR',  'ILB_STD_PCR',    'IlluminaB::Requests::PrePcrToPcr'      ],
    [ 'ILB_STD_PREPCR',  'ILB_STD_PCRR',   'IlluminaB::Requests::PrePcrToPcr'      ],
    [ 'ILB_STD_PCR',     'ILB_STD_PCRXP',  'IlluminaB::Requests::PcrToPcrXp'       ],
    [ 'ILB_STD_PCRR',    'ILB_STD_PCRRXP', 'IlluminaB::Requests::PcrToPcrXp'       ],
    [ 'ILB_STD_PCRXP',   'ILB_STD_STOCK',  'IlluminaB::Requests::PcrXpToStock'     ],
    [ 'ILB_STD_PCRRXP',  'ILB_STD_STOCK',  'IlluminaB::Requests::PcrXpToStock'     ]
  ]

  PLATE_PURPOSE_TYPE = {
    'ILB_STD_INPUT'   => IlluminaB::StockPlatePurpose,
    'ILB_STD_COVARIS' => IlluminaB::CovarisPlatePurpose,
    'ILB_STD_SH'      => PlatePurpose,
    'ILB_STD_PREPCR'  => PlatePurpose,
    'ILB_STD_PCR'     => IlluminaB::PcrPlatePurpose,
    'ILB_STD_PCRXP'   => IlluminaB::FinalPlatePurpose,
    'ILB_STD_PCRR'    => PlatePurpose,
    'ILB_STD_PCRRXP'  => IlluminaB::FinalPlatePurpose,
    'ILB_STD_STOCK'   => IlluminaB::StockTubePurpose,
    'ILB_STD_MX'      => IlluminaB::MxTubePurpose
  }

  def self.request_type_prefix
    "Illumina-B"
  end

  extend IlluminaHtp::PlatePurposes::PurposeHelpers

end


# We require all the plate and tube purpose files here as Rails eager loading does not play nicely with single table
# inheritance

['covaris_plate','final_plate','initial_stock_tube','mx_tube','pcr_plate','post_shear_qc_plate','stock_plate','stock_tube'].each do |type|
  require "#{Rails.root.to_s}/app/models/illumina_b/#{type}_purpose"
end

