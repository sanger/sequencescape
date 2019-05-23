# Used by {BarcodePrinter barcode printers} to identify which label type is loaded
# in them
class BarcodePrinterType < ApplicationRecord
  has_many :barcode_printers
  validates_presence_of :name
  validates_uniqueness_of :name, on: :create, message: 'already in use'
  # printer_type_id is used by the perl script printing service to decide on the positioning of information on the label

  def self.double_label?
    false
  end
end
