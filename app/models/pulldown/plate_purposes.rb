module Pulldown::PlatePurposes
  PULLDOWN_PLATE_PURPOSE_FLOWS = [
    [
      'WGS stock plate',
      'WGS fragmentation plate',
      'WGS fragment purification plate',
      'WGS library preparation plate',
      'WGS library plate',
      'WGS library PCR plate',
      'WGS amplified library plate',
      'WGS pooled amplified library plate'
    ], [
      'SC stock plate',
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
      'ISC stock plate',
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
end
