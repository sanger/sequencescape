# Base class for the all tube purposes, describes the role the associated
# {Tube} is playing within the lab, and my modify its behaviour.
# This is not an abstract class, and can be used directly.
# @see Purpose
class Tube::Purpose < ::Purpose
  self.default_prefix = 'NT'
  # TODO: change to purpose_id
  has_many :tubes, foreign_key: :plate_purpose_id

  # We use a lambda here as most tube subclasses won't be loaded at the point of evaluation. We'll
  # be performing this check so rarely that the performance hit is negligable.
  validates :target_type, presence: true, inclusion: { in: ->(_) { Tube.descendants.map(&:name) << 'Tube' } }
  before_validation :set_default_printer_type
  # Tubes of the general types have no stock plate!
  def stock_plate(_)
    nil
  end

  def library_source_plates(_)
    []
  end

  def create!(*args, &block)
    options = args.extract_options!
    options[:purpose] = self
    options[:barcode_prefix] ||= barcode_prefix
    target_class.create_with_barcode!(*args, options, &block).tap { |t| tubes << t }
  end

  def sibling_tubes(_tube)
    nil
  end

  # Define some simple helper methods
  class << self
    def stock_library_tube
      Tube::Purpose.create_with(
        target_type: 'StockLibraryTube'
      ).find_or_create_by!(name: 'Stock library')
    end

    def stock_mx_tube
      Tube::StockMx.create_with(
        target_type: 'StockMultiplexedLibraryTube'
      ).find_or_create_by!(name: 'Stock MX')
    end

    def standard_sample_tube
      Tube::Purpose.create_with(
        target_type: 'SampleTube'
      ).find_or_create_by!(name: 'Standard sample')
    end

    def standard_library_tube
      Tube::Purpose.create_with(
        target_type: 'LibraryTube'
      ).find_or_create_by!(name: 'Standard library')
    end

    def standard_mx_tube
      Tube::StandardMx.create_with(
        target_type: 'MultiplexedLibraryTube'
      ).find_or_create_by!(name: 'Standard MX')
    end
  end

  private

  def set_default_printer_type
    self.barcode_printer_type ||= BarcodePrinterType1DTube.first
  end
end

require_dependency 'qcable_tube_purpose'
require_dependency 'illumina_c/qc_pool_purpose'
require_dependency 'illumina_htp/mx_tube_purpose'
require_dependency 'illumina_htp/stock_tube_purpose'
require_dependency 'tube/standard_mx'
require_dependency 'tube/stock_mx'
