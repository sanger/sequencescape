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
    ],
    [
      'Cherrypicked',
      'Shear',
      'Post Shear',
      'AL Libs',
      'Lib PCR',
      'Lib PCRR',
      'Lib PCR-XP',
      'Lib PCRR-XP'
    ]
  ]

  TUBE_PURPOSE_FLOWS = [
    [
      'ILB_STD_STOCK',
      'ILB_STD_MX'
    ],
    [
      'Lib Pool',
      'Lib Pool Norm',
    ],
    [
      'Lib Pool Pippin',
      'Lib Pool Conc',
      'Lib Pool SS',
      'Lib Pool SS-XP',
      'Lib Pool SS-XP-Norm'
    ]
  ]

  BRANCHES = [
    [ 'ILB_STD_INPUT', 'ILB_STD_COVARIS', 'ILB_STD_SH', 'ILB_STD_PREPCR', 'ILB_STD_PCR', 'ILB_STD_PCRXP', 'ILB_STD_STOCK', 'ILB_STD_MX' ],
    [ 'ILB_STD_PREPCR', 'ILB_STD_PCRR', 'ILB_STD_PCRRXP' ],
    [ 'Cherrypicked', 'Shear', 'Post Shear', 'AL Libs', 'Lib PCR', 'Lib PCR-XP','Lib Pool','Lib Pool Norm'],
    [ 'Lib PCR-XP','Lib Pool Pippin', 'Lib Pool Conc', 'Lib Pool SS', 'Lib Pool SS-XP', 'Lib Pool SS-XP-Norm' ],
    [ 'AL Libs', 'Lib PCRR', 'Lib PCRR-XP' ]
  ]

  STOCK_PLATE_PURPOSE = 'ILB_STD_INPUT'

  # Don't have ILllumina B QC plates at the momnet...
  PLATE_PURPOSE_LEADING_TO_QC_PLATES = [
    'Post Shear', 'Lib PCR-XP', 'Lib PCRR-XP'
  ]

  PLATE_PURPOSES_TO_REQUEST_CLASS_NAMES = [
    [ 'ILB_STD_INPUT',   'ILB_STD_COVARIS','IlluminaB::Requests::InputToCovaris'   ],
    [ 'ILB_STD_COVARIS', 'ILB_STD_SH',     'IlluminaB::Requests::CovarisToSheared' ],
    [ 'ILB_STD_PREPCR',  'ILB_STD_PCR',    'IlluminaB::Requests::PrePcrToPcr'      ],
    [ 'ILB_STD_PREPCR',  'ILB_STD_PCRR',   'IlluminaB::Requests::PrePcrToPcr'      ],
    [ 'ILB_STD_PCR',     'ILB_STD_PCRXP',  'IlluminaB::Requests::PcrToPcrXp'       ],
    [ 'ILB_STD_PCRR',    'ILB_STD_PCRRXP', 'IlluminaB::Requests::PcrToPcrXp'       ],
    [ 'ILB_STD_PCRXP',   'ILB_STD_STOCK',  'IlluminaB::Requests::PcrXpToStock'     ],
    [ 'ILB_STD_PCRRXP',  'ILB_STD_STOCK',  'IlluminaB::Requests::PcrXpToStock'     ],

    [ 'Shear',           'Post Shear',      'IlluminaB::Requests::CovarisToSheared' ],
    [ 'AL Libs',         'Lib PCR',        'IlluminaB::Requests::PrePcrToPcr'      ],
    [ 'AL Libs',         'Lib PCRR',       'IlluminaB::Requests::PrePcrToPcr'      ],
    [ 'Lib PCR',         'Lib PCR-XP',     'IlluminaB::Requests::PcrToPcrXp'       ],
    [ 'Lib PCRR',        'Lib PCRR-XP',    'IlluminaB::Requests::PcrToPcrXp'       ],
    [ 'Lib PCR-XP',      'Lib Pool',       'IlluminaB::Requests::PcrXpToStock'     ],
    [ 'Lib PCRR-XP',     'Lib Pool',       'IlluminaB::Requests::PcrXpToStock'     ]
    [ 'Lib PCR-XP',      'Lib Pool Pippin', 'IlluminaB::Requests::PcrXpToStock'     ],
    [ 'Lib PCRR-XP',     'Lib Pool Pippin', 'IlluminaB::Requests::PcrXpToStock'     ]
  ]

  PLATE_PURPOSE_TYPE = {
    'ILB_STD_INPUT'       => IlluminaB::StockPlatePurpose,
    'ILB_STD_COVARIS'     => IlluminaB::CovarisPlatePurpose,
    'ILB_STD_SH'          => PlatePurpose,
    'ILB_STD_PREPCR'      => PlatePurpose,
    'ILB_STD_PCR'         => IlluminaB::PcrPlatePurpose,
    'ILB_STD_PCRXP'       => IlluminaB::FinalPlatePurpose,
    'ILB_STD_PCRR'        => PlatePurpose,
    'ILB_STD_PCRRXP'      => IlluminaB::FinalPlatePurpose,
    'ILB_STD_STOCK'       => IlluminaB::StockTubePurpose,
    'ILB_STD_MX'          => IlluminaB::MxTubePurpose,

    'Cherrypicked'        => IlluminaB::StockPlatePurpose,
    'Shear'               => IlluminaB::CovarisPlatePurpose,
    'Post Shear'          => PlatePurpose,
    'AL Libs'             => PlatePurpose,
    'Lib PCR'             => IlluminaB::PcrPlatePurpose,
    'Lib PCRR'            => PlatePurpose,
    'Lib PCR-XP'          => IlluminaB::TransferablePlatePurpose,
    'Lib PCRR-XP'         => IlluminaB::TransferablePlatePurpose,
    'Lib Pool'            => IlluminaB::InitialStockTubePurpose,
    'Lib Pool Pippin'     => IlluminaB::InitialStockTubePurpose,
    'Lib Pool Norm'       => IlluminaB::MxTubePurpose,
    'Lib Pool Conc'       => IlluminaB::StockTubePurpose,
    'Lib Pool SS'         => IlluminaB::StockTubePurpose,
    'Lib Pool SS-XP'      => IlluminaB::StockTubePurpose,
    'Lib Pool SS-XP-Norm' => IlluminaB::MxTubePurpose,

    'Post Shear QC'    => IlluminaB::PostShearQcPlatePurpose,
    'Lib PCR-XP QC'    => PlatePurpose,
    'Lib PCRR-XP QC'   => PlatePurpose

  }

  # Now have two flows. Need to be careful with migrations.
  class << self
    def create_tube_purposes
      IlluminaB::PlatePurposes::TUBE_PURPOSE_FLOWS.each do |flow|
        create_tube_flow(flow)
      end
    end

    def create_tube_flow(flow)
      raise "Flow already exists" if Purpose.find_by_name(flow.first).present?
      stock_tube = create_tube_purpose(flow.shift, :target_type => 'StockMultiplexedLibraryTube')
      flow.each(&method(:create_tube_purpose))
    end

    def destroy_tube_purposes
      IlluminaB::PlatePurposes::TUBE_PURPOSE_FLOWS.each do |flow|
        Tube::Purpose.find_all_by_name(flow.flatten).map(&:destroy)
      end
    end

    def create_plate_flow(flow)
      raise "Flow already exists" if Purpose.find_by_name(flow.first).present?
      stock_plate = create_plate_purpose(
        flow.shift,
        :can_be_considered_a_stock_plate => true,
        :default_state                   => 'passed',
        :cherrypickable_target           => true,
        :cherrypick_filters              => [
          'Cherrypick::Strategy::Filter::ByOverflow',
          'Cherrypick::Strategy::Filter::ByEmptySpaceUsage',
          'Cherrypick::Strategy::Filter::BestFit',
          'Cherrypick::Strategy::Filter::BySpecies',
          'Cherrypick::Strategy::Filter::InternallyOrderPlexBySubmission'
        ]
      )
      request_type_for(stock_plate).acceptable_plate_purposes << stock_plate

      flow.each do |name|
        create_plate_purpose(name, :default_location => library_creation_freezer)
      end
    end

    def create_plate_purposes
      IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS.each do |flow|
        create_plate_flow(flow)
      end
      create_qc_plates
    end

    def destroy_plate_purposes
      IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS.each do |flow|
        PlatePurpose.find_all_by_name(flow.flatten).map(&:destroy)
      end
    end

    def create_branch(branch)
      branch.inject(Purpose.find_by_name(branch.shift)) do |parent, child|
        Purpose.find_by_name(child).tap do |child_purpose|
          parent.child_relationships.create!(:child => child_purpose, :transfer_request_type => request_type_between(parent, child_purpose))
        end
      end
    end

    def create_branches
      IlluminaB::PlatePurposes::BRANCHES.each do |branch|
        create_branch(branch)
      end
    end

    def destroy_branches

    end

    def request_type_for(stock_plate)
      # Only have one at the moment
      RequestType.find_by_key('illumina_b_std') or raise "Cannot find Illumina B STD request type"
    end
    private :request_type_for

    def purpose_for(name)
      IlluminaB::PlatePurposes::PLATE_PURPOSE_TYPE[name]
    end
    private :purpose_for

    def request_type_between(parent, child)
      _, _, request_class = IlluminaB::PlatePurposes::PLATE_PURPOSES_TO_REQUEST_CLASS_NAMES.detect { |a,b,_| (parent.name == a) && (child.name == b) }
      return RequestType.transfer if request_class.nil?
      request_type_name = "Illumina-B #{parent.name}-#{child.name}"
      RequestType.create!(:name => request_type_name, :key => request_type_name.gsub(/\W+/, '_'), :request_class_name => request_class, :asset_type => 'Well', :order => 1)
    end
    private :request_type_between

    def library_creation_freezer
      Location.find_by_name('Library creation freezer') or raise "Cannot find library creation freezer"
    end
    private :library_creation_freezer

    def create_plate_purpose(plate_purpose_name, options = {})
      purpose_for(plate_purpose_name).create!(options.reverse_merge(
        :name                  => plate_purpose_name,
        :cherrypickable_target => false,
        :cherrypick_direction  => 'column'
      )).tap do |plate_purpose|
        plate_purpose.barcode_printer_type = BarcodePrinterType.find_by_type('BarcodePrinterType96Plate')||plate_purpose.barcode_printer_type
      end
    end
    private :create_plate_purpose

    def create_tube_purpose(tube_purpose_name, options = {})
      purpose = purpose_for(tube_purpose_name)
      target_type = purpose == IlluminaB::MxTubePurpose ? 'MultiplexedLibraryTube' : 'StockMultiplexedLibraryTube'
      purpose.create!(options.reverse_merge(
        :name                 => tube_purpose_name,
        :target_type          => target_type,
        :barcode_printer_type => BarcodePrinterType.find_by_type('BarcodePrinterType1DTube')
      ))
    end
    private :create_tube_purpose

    def create_qc_plates
      ActiveRecord::Base.transaction do
        IlluminaB::PlatePurposes::PLATE_PURPOSE_LEADING_TO_QC_PLATES.each do |name|
          qc_plate_purpose = purpose_for("#{name} QC").create!(:name => "#{name} QC")
          plate_purpose = PlatePurpose.find_by_name(name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
          plate_purpose.child_relationships.create!(:child => qc_plate_purpose, :transfer_request_type => RequestType.find_by_name('Transfer'))
        end
      end
    end
  end
end
