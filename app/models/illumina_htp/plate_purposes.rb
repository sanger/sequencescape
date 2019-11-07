# This module contains methods associated with the now defunct Illumina-B pipleine
# (post merge with pulldown).
#
# This module was used to generate the purposes and their associations as part of
# both the seeds and the original migration.
#
# Removal of this code shouldn't affect production, but will disrupt seeds,
# and potentially a number of cucumber features. It will probably also require
# the corresponding search objects to be deprecated.
#
# @todo #2396 Remove
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
      'Lib PCRR-XP',
      # Alternative branch for ILA
      'Post Shear XP',
      # Plate based pooling
      'Lib Norm',
      'Lib Norm 2',
      'Lib Norm 2 Pool'
    ],
    [
      'PF Cherrypicked',
      'PF Shear',
      'PF Post Shear',
      'PF Post Shear XP',
      'PF Lib',
      'PF Lib XP',
      'PF Lib XP2',
      'PF EM Pool',
      'PF Lib Norm'
    ]
  ].freeze

  TUBE_PURPOSE_FLOWS = [
    [
      'Lib Pool',
      'Lib Pool Norm'
    ],
    [
      'Lib Pool Pippin',
      'Lib Pool Conc',
      'Lib Pool SS',
      'Lib Pool SS-XP',
      'Lib Pool SS-XP-Norm'
    ],
    [
      'Cap Lib Pool Norm'
    ]
  ].freeze

  QC_TUBE_PURPOSE_FLOWS = [
    [
      'PF MiSeq Stock',
      'PF MiSeq QC'
    ],
    ['PF MiSeq QCR']
  ].freeze

  BRANCHES = [
    ['PF Cherrypicked', 'PF Shear', 'PF Post Shear', 'PF Post Shear XP', 'PF Lib', 'PF Lib XP', 'PF Lib XP2', 'PF EM Pool', 'PF Lib Norm'],
    ['PF Lib XP2', 'PF MiSeq Stock', 'PF MiSeq QC'],
    ['PF MiSeq Stock', 'PF MiSeq QCR'],
    ['Cherrypicked', 'Shear', 'Post Shear', 'AL Libs', 'Lib PCR', 'Lib PCR-XP', 'Lib Pool', 'Lib Pool Norm'],
    ['Lib PCR-XP', 'Lib Pool Pippin', 'Lib Pool Conc', 'Lib Pool SS', 'Lib Pool SS-XP', 'Lib Pool SS-XP-Norm'],
    ['Lib PCRR', 'Lib PCRR-XP', 'Lib Pool Pippin'],
    ['Lib PCR-XP', 'ISC lib pool'],
    ['Lib PCR-XP', 'Lib Norm', 'Lib Norm 2', 'Lib Norm 2 Pool'],
    ['Lib PCRR-XP', 'ISC lib pool'],
    ['Post Shear', 'Post Shear XP', 'AL Libs']
  ].freeze

  STOCK_PLATE_PURPOSE = 'Cherrypicked'.freeze

  OUTPUT_PLATE_PURPOSES = ['Lib PCR-XP', 'Lib PCRR-XP'].freeze

  PLATE_PURPOSE_LEADING_TO_QC_PLATES = [
    'Post Shear', 'Lib PCR-XP', 'Lib PCRR-XP', 'Lib Norm', 'PF EM Pool'
  ].freeze

  STOCK_PLATE_PURPOSE_TO_OUTER_REQUEST = {
    'Cherrypicked' => 'illumina_b_shared'
  }.freeze

  PLATE_PURPOSE_TYPE = {
    'PF Cherrypicked' => PlatePurpose::Input,
    'PF Shear' => PlatePurpose::InitialPurpose,
    'PF Post Shear' => PlatePurpose,
    'PF Post Shear XP' => PlatePurpose,
    'PF Lib' => PlatePurpose,
    'PF Lib XP' => PlatePurpose,
    'PF Lib XP2' => IlluminaHtp::LibraryCompleteOnQcPurpose,
    'PF EM Pool' => PlatePurpose,
    'PF Lib Norm' => IlluminaHtp::PooledPlatePurpose,
    'PF MiSeq Stock' => IlluminaHtp::StockTubePurpose,
    'PF MiSeq QC' => IlluminaC::QcPoolPurpose,
    'PF MiSeq QCR' => IlluminaC::QcPoolPurpose,

    'Cherrypicked' => PlatePurpose::Input,
    'Shear' => PlatePurpose::InitialPurpose,
    'Post Shear' => PlatePurpose,
    'AL Libs' => PlatePurpose,
    'Lib PCR' => PlatePurpose,
    'Lib PCRR' => PlatePurpose,
    'Lib PCR-XP' => IlluminaHtp::TransferablePlatePurpose,
    'Lib PCRR-XP' => IlluminaHtp::TransferablePlatePurpose,
    'Lib Pool' => IlluminaHtp::InitialStockTubePurpose,
    'Lib Pool Pippin' => IlluminaHtp::InitialStockTubePurpose,
    'Lib Pool Norm' => IlluminaHtp::MxTubePurpose,
    'Lib Pool Conc' => IlluminaHtp::StockTubePurpose,
    'Lib Pool SS' => IlluminaHtp::StockTubePurpose,
    'Lib Pool SS-XP' => IlluminaHtp::StockTubePurpose,
    'Lib Pool SS-XP-Norm' => IlluminaHtp::MxTubePurpose,
    'Post Shear XP' => PlatePurpose,

    'Post Shear QC' => IlluminaHtp::PostShearQcPlatePurpose,
    'Lib PCR-XP QC' => PlatePurpose,
    'Lib PCRR-XP QC' => PlatePurpose,
    'Lib Norm QC' => PlatePurpose,
    'PF EM Pool QC' => PlatePurpose,

    'Lib Norm' => IlluminaHtp::InitialDownstreamPlatePurpose,
    'Lib Norm 2' => IlluminaHtp::NormalizedPlatePurpose,
    'Lib Norm 2 Pool' => IlluminaHtp::PooledPlatePurpose,

    'Cap Lib Pool Norm' => IlluminaHtp::MxTubeNoQcPurpose

  }.freeze

  def self.request_type_prefix
    'Illumina'
  end

  module PurposeHelpers
    def create_tube_purposes
      self::TUBE_PURPOSE_FLOWS.each do |flow|
        create_tube_flow(flow)
      end
      self::QC_TUBE_PURPOSE_FLOWS.each do |flow|
        create_qc_tube_flow(flow)
      end
    end

    def create_tube_flow(flow_o)
      flow = flow_o.clone
      raise 'Flow already exists' if Purpose.find_by(name: flow.first).present?

      create_tube_purpose(flow.pop, target_type: 'MultiplexedLibraryTube')
      flow.each(&method(:create_tube_purpose))
    end

    def create_qc_tube_flow(flow_o)
      flow = flow_o.clone
      raise 'Flow already exists' if Purpose.find_by(name: flow.first).present?

      flow.each do |purpose|
        create_tube_purpose(purpose, target_type: 'QcTube')
      end
    end

    def destroy_tube_purposes
      self::TUBE_PURPOSE_FLOWS.each do |flow|
        Tube::Purpose.where(name: flow.flatten).map(&:destroy)
      end
    end

    def create_plate_flow(flow_o)
      flow = flow_o.clone
      raise 'Flow already exists' if Purpose.find_by(name: flow.first).present?

      stock_plate = create_plate_purpose(
        flow.shift,
        stock_plate: true,
        default_state: 'passed',
        cherrypickable_target: true
      )

      flow.each do |name|
        create_plate_purpose(name, source_purpose_id: stock_plate.id)
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
        PlatePurpose.where(name: flow.flatten).map(&:destroy)
      end
    end

    def create_branch(branch_o)
      branch = branch_o.clone
      branch.inject(Purpose.find_by!(name: branch.shift)) do |parent, child|
        Purpose.find_by!(name: child).tap do |child_purpose|
          parent.child_relationships.create!(child: child_purpose)
        end
      end
    end

    def create_branches
      self::BRANCHES.each do |branch|
        create_branch(branch)
      end
    end

    def purpose_for(name)
      self::PLATE_PURPOSE_TYPE[name] || raise("NO class configured for #{name}")
    end
    private :purpose_for

    def create_plate_purpose(plate_purpose_name, options = {})
      purpose_for(plate_purpose_name).create!(options.reverse_merge(
                                                name: plate_purpose_name,
                                                cherrypickable_target: false,
                                                cherrypick_direction: 'column',
                                                stock_plate: self::OUTPUT_PLATE_PURPOSES.include?(plate_purpose_name),
                                                asset_shape_id: AssetShape.default.id
                                              )).tap do |plate_purpose|
        plate_purpose.barcode_printer_type = BarcodePrinterType.find_by(type: 'BarcodePrinterType96Plate') || plate_purpose.barcode_printer_type
      end
    end

    def create_tube_purpose(tube_purpose_name, options = {})
      purpose = purpose_for(tube_purpose_name)
      target_type = 'StockMultiplexedLibraryTube'
      purpose.create!(options.reverse_merge(
                        name: tube_purpose_name,
                        target_type: target_type,
                        barcode_printer_type: BarcodePrinterType1DTube.first
                      ))
    end
    private :create_tube_purpose

    def create_qc_plates
      ActiveRecord::Base.transaction do
        self::PLATE_PURPOSE_LEADING_TO_QC_PLATES.each do |name|
          create_qc_plate_for(name)
        end
      end
    end

    def create_qc_plate_for(name)
      qc_plate_purpose = purpose_for("#{name} QC").create!(name: "#{name} QC", cherrypickable_target: false)
      plate_purpose = Purpose.find_by!(name: name)
      plate_purpose.child_relationships.create!(child: qc_plate_purpose)
    end
  end

  extend PurposeHelpers
end
