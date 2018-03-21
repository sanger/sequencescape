# Base class for the all tube purposes
class Tube::Purpose < ::Purpose
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
    target_class.create_with_barcode!(*args, &block).tap { |t| tubes << t }
  end

  def sibling_tubes(_tube)
    nil
  end

  # Define some simple helper methods
  class << self
    ['Stock', 'Standard'].each do |purpose_type|
      ['sample', 'library', 'MX'].each do |tube_type|
        name = "#{purpose_type} #{tube_type}"
        define_method("#{name.downcase.tr(' ', '_')}_tube") do
          find_by(name: name) or raise "Cannot find #{name} tube"
        end
      end
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
