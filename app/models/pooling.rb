class Pooling
  include ActiveModel::Model
  include SampleManifestExcel::Tags::ClashesFinder

  attr_accessor :barcodes, :source_assets, :stock_mx_tube_required, :stock_mx_tube, :standard_mx_tube, :barcode_printer, :count

  validates_presence_of :source_assets, message: 'were not scanned or were not found in sequencescape'
  validate :all_source_assets_are_in_sqsc, if: :source_assets?
  validate :source_assets_can_be_pooled, if: :source_assets?

  def execute
    @stock_mx_tube = Tube::Purpose.stock_mx_tube.create!(name: '(s)') if stock_mx_tube_required?
    @standard_mx_tube = Tube::Purpose.standard_mx_tube.create!
    transfer
    execute_print_job
  end

  def transfer
    target_assets.each do |target_asset|
      source_assets.each do |source_asset|
        TransferRequest.create!(asset: source_asset, target_asset: target_asset)
      end
    end
    message[:notice] = (message[:notice] || '') + success
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
    barcode_printer.present?
  end

  def print_job
    @print_job ||= LabelPrinter::PrintJob.new(barcode_printer,
                                              LabelPrinter::Label::MultiplexedTube,
                                              assets: target_assets, count: count)
  end

  def message
    @message ||= {}
  end

  private

  def tags_combinations
    @tags_combinations || []
  end

  def source_assets?
    source_assets.present?
  end

  def find_source_assets
    @assets_not_in_sqsc = []
    barcodes.map do |barcode|
      asset = Asset.find_from_any_barcode(barcode)
      @assets_not_in_sqsc << barcode unless asset.present?
      asset
    end.compact
  end

  def assets_not_in_sqsc
    @assets_not_in_sqsc || []
  end

  def all_source_assets_are_in_sqsc
    errors.add(:source_assets, "with barcode(s) #{assets_not_in_sqsc.join(', ')} were not found in sequencescape") unless assets_not_in_sqsc.empty?
  end

  def source_assets_can_be_pooled
    assets_with_no_aliquot = []
    @tags_combinations = []
    source_assets.each do |asset|
      if asset.aliquots.empty?
        assets_with_no_aliquot << asset.ean13_barcode
        @tags_combinations << []
      else
        asset.aliquots.each { |aliquot| @tags_combinations << aliquot.tags_combination }
      end
    end
    errors.add(:source_assets, "with barcode(s) #{assets_with_no_aliquot.join(', ')} do not have any aliquots") unless assets_with_no_aliquot.empty?
    errors.add(:tags_combinations, tags_clash_message) if duplicates.present?
  end

  def duplicates
    @duplicates ||= find_tags_clash(tags_combinations)
  end

  def tags_clash_message
    create_tags_clashes_message(duplicates.except([]))
  end

  def execute_print_job
    if print_job_required?
      if print_job.execute
        message[:notice] = (message[:notice] || '') + print_job.success
      else
        message[:error] = (message[:error] || '') + print_job.errors.full_messages.join('; ')
      end
    end
  end

  def success
    "Samples were transferred successfully to standard_mx_tube #{standard_mx_tube.sanger_human_barcode} " +
      ("and stock_mx_tube #{stock_mx_tube.sanger_human_barcode} " if stock_mx_tube.present?).to_s
  end
end
