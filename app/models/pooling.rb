# frozen_string_literal: true

# Used by {PoolingsController} to take multiple scanned {Tube} barcodes containing
# one or more {Aliquot aliquots} and use them to generate a new {MultiplexedLibraryTube}
class Pooling
  include ActiveModel::Model

  attr_writer :barcodes, :source_assets
  attr_accessor :stock_mx_tube_required, :stock_mx_tube, :standard_mx_tube, :barcode_printer, :count

  validates :source_assets, presence: { message: 'were not scanned or were not found in Sequencescape' }
  validate :all_source_assets_are_in_sqsc, if: :source_assets?
  validate :source_assets_can_be_pooled, if: :source_assets?
  validate :expected_numbers_found, if: :source_assets?

  def execute
    return false unless valid?

    if stock_mx_tube_required?
      @stock_mx_tube = Tube::Purpose.stock_mx_tube.create!(name: '(s)')
      @stock_mx_tube.parents = source_assets
    end

    @standard_mx_tube = Tube::Purpose.standard_mx_tube.create!
    @standard_mx_tube.parents = @stock_mx_tube ? [@stock_mx_tube] : source_assets
    transfer
    execute_print_job
    true
  end

  def transfer
    each_transfer do |source_asset, target_asset|
      # These transfers are not being performed to fulfil a specific request, so we explicitly
      # pass in a Request Null object. This will disable the attempt to detect an outer request.
      # We don't use nil as its *far* to easy to end up with nil by accident, so basing key behaviour
      # off it is risky.
      TransferRequest.create!(asset: source_asset, target_asset:, outer_request: Request::None.new)
    end
    message[:notice] = message[:notice] + success
  end

  def each_transfer
    source_assets.each { |source_asset| yield source_asset, @stock_mx_tube || @standard_mx_tube }
    return unless stock_mx_tube_required?

    yield @stock_mx_tube, @standard_mx_tube
  end

  def source_assets
    @source_assets ||= find_source_assets
  end

  def target_assets
    @target_assets ||= [stock_mx_tube, standard_mx_tube].compact
  end

  def barcodes
    @barcodes || []
  end

  def stock_mx_tube_required?
    stock_mx_tube_required.present?
  end

  def print_job_required?
    barcode_printer.present? && count.to_i.positive?
  end

  def print_job
    @print_job ||=
      LabelPrinter::PrintJob.new(
        barcode_printer,
        LabelPrinter::Label::MultiplexedTube,
        assets: target_assets,
        count:
      )
  end

  def message
    @message ||= Hash.new('')
  end

  def tag_clash_report
    @tag_clash_report ||= Pooling::TagClashReport.new(self)
  end

  private

  def tag_clash?
    tag_clash_report.tag_clash?
  end

  def source_assets?
    source_assets.present?
  end

  def find_source_assets
    Labware.includes(aliquots: %i[tag tag2 library]).with_barcode(barcodes)
  end

  # Returns a list of scanned barcodes which could not be found in Sequencescape
  # This allows ANY asset barcode to match, either via human or machine readable formats
  # =~ is a fuzzy matcher
  def assets_not_in_sqsc
    @assets_not_in_sqsc ||=
      barcodes.reject { |barcode| found_barcodes.detect { |found_barcode| found_barcode =~ barcode } }
  end

  def found_barcodes
    source_assets.flat_map(&:barcodes)
  end

  def all_source_assets_are_in_sqsc
    return unless assets_not_in_sqsc.present?
      errors.add(:source_assets, "with barcode(s) #{assets_not_in_sqsc.join(', ')} were not found in Sequencescape")
    
  end

  def expected_numbers_found
    return unless source_assets.length != barcodes.length
      errors.add(:source_assets, "found #{source_assets.length} assets, but #{barcodes.length} barcodes were scanned.")
    
  end

  def source_assets_can_be_pooled
    assets_with_no_aliquot = []
    source_assets.each { |asset| assets_with_no_aliquot << asset.machine_barcode if asset.aliquots.empty? }
    if assets_with_no_aliquot.present?
      errors.add(:source_assets, "with barcode(s) #{assets_with_no_aliquot.join(', ')} do not have any aliquots")
    end
    errors.add(:tags_combinations, 'are not compatible and result in a tag clash') if tag_clash?
  end

  def execute_print_job # rubocop:todo Metrics/AbcSize
    return unless print_job_required?

    if print_job.execute
      message[:notice] = message[:notice] + print_job.success
    else
      message[:error] = message[:error] + print_job.errors.full_messages.join('; ')
    end
  end

  def success
    "Samples were transferred successfully to standard_mx_tube #{standard_mx_tube.human_barcode} " +
      ("and stock_mx_tube #{stock_mx_tube.human_barcode} " if stock_mx_tube.present?).to_s
  end
end
