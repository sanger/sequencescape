module IlluminaHtp::PlatePurposes
  PLATE_PURPOSE_FLOWS = [
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
    [ 'Cherrypicked', 'Shear', 'Post Shear', 'AL Libs', 'Lib PCR', 'Lib PCR-XP','Lib Pool','Lib Pool Norm'],
    [ 'Lib PCR-XP','Lib Pool Pippin', 'Lib Pool Conc', 'Lib Pool SS', 'Lib Pool SS-XP', 'Lib Pool SS-XP-Norm' ],
    [ 'AL Libs', 'Lib PCRR', 'Lib PCRR-XP' ],
    ['Lib PCR-XP','ISC lib pool']
  ]

  STOCK_PLATE_PURPOSE = 'Cherrypicked'

  OUTPUT_PLATE_PURPOSES = ['Lib PCR-XP','Lib PCRR-XP']

  # Don't have ILllumina B QC plates at the momnet...
  PLATE_PURPOSE_LEADING_TO_QC_PLATES = [
    'Post Shear', 'Lib PCR-XP', 'Lib PCRR-XP'
  ]

  STOCK_PLATE_PURPOSE_TO_OUTER_REQUEST = {
    'Cherrypicked'  => 'illumina_b_shared'
  }

  PLATE_PURPOSES_TO_REQUEST_CLASS_NAMES = [
    [ 'Shear',           'Post Shear',      'IlluminaHtp::Requests::CovarisToSheared'      ],
    [ 'Post Shear',       'AL Libs',        'IlluminaHtp::Requests::PostShearToAlLibs'     ],
    [ 'AL Libs',         'Lib PCR',         'IlluminaHtp::Requests::PrePcrToPcr'           ],
    [ 'AL Libs',         'Lib PCRR',        'IlluminaHtp::Requests::PrePcrToPcr'           ],
    [ 'Lib PCR',         'Lib PCR-XP',      'IlluminaHtp::Requests::PcrToPcrXp'            ],
    [ 'Lib PCRR',        'Lib PCRR-XP',     'IlluminaHtp::Requests::PcrToPcrXp'            ],
    [ 'Lib PCR-XP',      'Lib Pool',        'IlluminaHtp::Requests::PcrXpToPool'           ],
    [ 'Lib PCRR-XP',     'Lib Pool',        'IlluminaHtp::Requests::PcrXpToPool'           ],
    [ 'Lib Pool SS',     'Lib Pool SS-XP',  'IlluminaHtp::Requests::LibPoolSsToLibPoolSsXp'],
    [ 'Lib PCR-XP',      'Lib Pool Pippin', 'IlluminaHtp::Requests::PcrXpToPoolPippin'     ],
    [ 'Lib PCRR-XP',     'Lib Pool Pippin', 'IlluminaHtp::Requests::PcrXpToPoolPippin'     ]
  ]

  PLATE_PURPOSE_TYPE = {
    'Cherrypicked'        => IlluminaHtp::StockPlatePurpose,
    'Shear'               => IlluminaHtp::CovarisPlatePurpose,
    'Post Shear'          => PlatePurpose,
    'AL Libs'             => PlatePurpose,
    'Lib PCR'             => IlluminaHtp::LibPcrPlatePurpose,
    'Lib PCRR'            => PlatePurpose,
    'Lib PCR-XP'          => IlluminaHtp::TransferablePlatePurpose,
    'Lib PCRR-XP'         => IlluminaHtp::TransferablePlatePurpose,
    'Lib Pool'            => IlluminaHtp::InitialStockTubePurpose,
    'Lib Pool Pippin'     => IlluminaHtp::InitialStockTubePurpose,
    'Lib Pool Norm'       => IlluminaHtp::MxTubePurpose,
    'Lib Pool Conc'       => IlluminaHtp::StockTubePurpose,
    'Lib Pool SS'         => IlluminaHtp::StockTubePurpose,
    'Lib Pool SS-XP'      => IlluminaHtp::StockTubePurpose,
    'Lib Pool SS-XP-Norm' => IlluminaHtp::MxTubePurpose,

    'Post Shear QC'    => IlluminaHtp::PostShearQcPlatePurpose,
    'Lib PCR-XP QC'    => PlatePurpose,
    'Lib PCRR-XP QC'   => PlatePurpose

  }

  def self.request_type_prefix
    "Illumina"
  end

  module PurposeHelpers


    def create_tube_purposes
      self::TUBE_PURPOSE_FLOWS.each do |flow|
        create_tube_flow(flow)
      end
    end

    def create_tube_flow(flow)
      raise "Flow already exists" if Purpose.find_by_name(flow.first).present?
      create_tube_purpose(flow.pop, :target_type => 'MultiplexedLibraryTube')
      flow.each(&method(:create_tube_purpose))
    end

    def destroy_tube_purposes
      self::TUBE_PURPOSE_FLOWS.each do |flow|
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
      self::PLATE_PURPOSE_FLOWS.each do |flow|
        create_plate_flow(flow)
      end
      create_qc_plates
    end

    def destroy_plate_purposes
      self::PLATE_PURPOSE_FLOWS.each do |flow|
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
      self::BRANCHES.each do |branch|
        create_branch(branch)
      end
    end

    def destroy_branches

    end

    def request_type_for(stock_plate)
      key = self::STOCK_PLATE_PURPOSE_TO_OUTER_REQUEST[stock_plate.name]
      RequestType.find_by_key(key) or raise "Cannot find #{key} request type"
    end
    private :request_type_for

    def purpose_for(name)
      self::PLATE_PURPOSE_TYPE[name]
    end
    private :purpose_for

    def request_type_between(parent, child)
      _, _, request_class = self::PLATE_PURPOSES_TO_REQUEST_CLASS_NAMES.detect { |a,b,_| (parent.name == a) && (child.name == b) }
      return RequestType.transfer if request_class.nil?
      request_type_name = "#{request_type_prefix} #{parent.name}-#{child.name}"
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
        :cherrypick_direction  => 'column',
        :can_be_considered_a_stock_plate => self::OUTPUT_PLATE_PURPOSES.include?(plate_purpose_name)
      )).tap do |plate_purpose|
        plate_purpose.barcode_printer_type = BarcodePrinterType.find_by_type('BarcodePrinterType96Plate')||plate_purpose.barcode_printer_type
      end
    end
    private :create_plate_purpose

    def create_tube_purpose(tube_purpose_name, options = {})
      purpose = purpose_for(tube_purpose_name)
      target_type = 'StockMultiplexedLibraryTube'
      purpose.create!(options.reverse_merge(
        :name                 => tube_purpose_name,
        :target_type          => target_type,
        :barcode_printer_type => BarcodePrinterType.find_by_type('BarcodePrinterType1DTube')
      ))
    end
    private :create_tube_purpose

    def create_qc_plates
      ActiveRecord::Base.transaction do
        self::PLATE_PURPOSE_LEADING_TO_QC_PLATES.each do |name|
          qc_plate_purpose = purpose_for("#{name} QC").create!(:name => "#{name} QC", :cherrypickable_target => false)
          plate_purpose = PlatePurpose.find_by_name(name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
          plate_purpose.child_relationships.create!(:child => qc_plate_purpose, :transfer_request_type => RequestType.find_by_name('Transfer'))
        end
      end
    end
  end

  extend PurposeHelpers
end
