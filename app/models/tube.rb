class Tube < Aliquot::Receptacle
  include LocationAssociation::Locatable
  include Barcode::Barcodeable

  named_scope :include_scanned_into_lab_event, :include => :scanned_into_lab_event

  # The type of the printer that should be used for tubes is the 1D tube printer.
  def self.barcode_type
    return @barcode_type if @barcode_type.present?
    barcode_printer_for_1d_tubes = BarcodePrinterType.find_by_name('1D Tube') or raise StandardError, 'Cannot find 1D tube printer'
    @barcode_type = barcode_printer_for_1d_tubes.printer_type_id
  end

  delegate :barcode_type, :to => 'self.class'

  def name_for_label
    (primary_aliquot.nil? or primary_aliquot.sample.sanger_sample_id.blank?) ? self.name : primary_aliquot.sample.shorten_sanger_sample_id
  end
end
