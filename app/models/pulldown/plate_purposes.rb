module Pulldown::PlatePurposes
  PLATE_PURPOSE_FLOWS = [
    [
      'WGS stock DNA',
      'WGS Covaris',
      'WGS post-Cov',
      'WGS post-Cov-XP',
      'WGS lib',
      'WGS lib PCR',
      'WGS lib PCR-XP',
      'WGS lib pool'
    ], [
      'SC stock DNA',
      'SC Covaris',
      'SC post-Cov',
      'SC post-Cov-XP',
      'SC lib',
      'SC lib PCR',
      'SC lib PCR-XP',
      'SC hyb',
      'SC cap lib',
      'SC cap lib PCR',
      'SC cap lib PCR-XP',
      'SC cap lib pool'
    ], [
      'ISC stock DNA',
      'ISC Covaris',
      'ISC post-Cov',
      'ISC post-Cov-XP',
      'ISC lib',
      'ISC lib PCR',
      'ISC lib PCR-XP',
      'ISC lib pool',
      'ISC hyb',
      'ISC cap lib',
      'ISC cap lib PCR',
      'ISC cap lib PCR-XP',
      'ISC cap lib pool'
    ], [
      'Lib PCR-XP',
      'ISC-HTP lib pool',
      'ISC-HTP hyb',
      'ISC-HTP cap lib',
      'ISC-HTP cap lib PCR',
      'ISC-HTP cap lib PCR-XP',
      'ISC-HTP cap lib pool'
    ]
  ]

  PLATE_PURPOSE_TYPE = {
    'ISC-HTP lib pool'       => Pulldown::InitialDownstreamPlatePurpose,
    'ISC-HTP hyb'            => IlluminaHtp::DownstreamPlatePurpose,
    'ISC-HTP cap lib'        => IlluminaHtp::DownstreamPlatePurpose,
    'ISC-HTP cap lib PCR'    => IlluminaHtp::DownstreamPlatePurpose,
    'ISC-HTP cap lib PCR-XP' => IlluminaHtp::DownstreamPlatePurpose,
    'ISC-HTP cap lib pool'   => IlluminaHtp::DownstreamPlatePurpose
  }

  PLATE_PURPOSE_LEADING_TO_QC_PLATES = [
    'WGS post-Cov',
    'WGS post-Cov-XP',
    'WGS lib PCR-XP',

    'SC post-Cov',
    'SC post-Cov-XP',
    'SC lib PCR-XP',
    'SC cap lib PCR-XP',

    'ISC post-Cov',
    'ISC post-Cov-XP',
    'ISC lib PCR-XP',
    'ISC cap lib PCR-XP'
  ]


  PLATE_PURPOSES_TO_REQUEST_CLASS_NAMES = [
    [ 'Lib PCR-XP',      'ISC-HTP lib pool', 'Pulldown::Requests::PcrXpToIscLibPool'     ],
    [ 'Lib PCRR-XP',     'ISC-HTP lib pool', 'Pulldown::Requests::PcrXpToIscLibPool'     ]
  ]

  STOCK_PLATE_PURPOSES = ['WGS stock DNA','SC stock DNA','ISC stock DNA']

  class << self

    def create_purposes(branch)
      initial = Purpose.find_by_name!(branch.shift)
      branch.inject(initial) do |parent,new_purpose_name|
        Pulldown::PlatePurposes::PLATE_PURPOSE_TYPE[new_purpose_name].create!(:name => new_purpose_name).tap do |child_purpose|
          parent.child_relationships.create!(:child => child_purpose, :transfer_request_type => request_type_between(parent,child_purpose))
        end
      end
    end

    def request_type_between(parent, child)
      _, _, request_class = self::PLATE_PURPOSES_TO_REQUEST_CLASS_NAMES.detect { |a,b,_| (parent.name == a) && (child.name == b) }
      return RequestType.transfer if request_class.nil?
      request_type_name = "Illumina A #{parent.name}-#{child.name}"
      RequestType.create!(:name => request_type_name, :key => request_type_name.gsub(/\W+/, '_'), :request_class_name => request_class, :asset_type => 'Well', :order => 1)
    end
    private :request_type_between

  end

end
