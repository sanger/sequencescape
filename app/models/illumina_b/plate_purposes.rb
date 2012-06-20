module IlluminaB::PlatePurposes
  PLATE_PURPOSE_FLOWS = [
    [
      'ILB_STD_INPUT',
      'ILB_STD_COVARIS',
      'ILB_STD_SH',
      'ILB_STD_PREPCR',
      'ILB_STD_PCR',
      'ILB_STD_PCRXP'
    ]
  ]

  BRANCHES = {
  }

  STOCK_PLATE_PURPOSE = 'ILB_STD_INPUT'

  # Don't have ILllumina B QC plates at the momnet...
  PLATE_PURPOSE_LEADING_TO_QC_PLATES = [
  ]

  def self.stock_plate_class
    IlluminaB::StockPlatePurpose
  end

  def self.plate_direction
    'row'
  end

  PLATE_PURPOSE_TYPE = {
    'ILB_STD_INPUT' => IlluminaB::StockPlatePurpose,
    'ILB_STD_COVARIS' => IlluminaB::CovarisPlatePurpose,
    'ILB_STD_PREPCR' => PlatePurpose,
    'ILB_STD_PCRXP' => IlluminaB::FinalPlatePurpose,
    'ILB_STD_SH' => PlatePurpose,
    'ILB_STD_PCR' => IlluminaB::PcrPlatePurpose
  }

  def self.request_type_for(stock_plate)
    # Only have one at the moment
    RequestType.find_by_key('illumina_b_std')
  end

end
