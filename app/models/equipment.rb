class Equipment < ActiveRecord::Base

  validates_presence_of :name, :equipment_type
  before_validation :set_defaults
  after_create :update_barcode

  def set_defaults
    self.prefix||='XX'
  end

  def update_barcode
    self.ean13_barcode = Barcode.calculate_barcode(prefix, id)
    save!
  end

  def suffix
    Barcode.calculate_checksum(prefix, id)
  end

  def print(barcode_printer)
    printables = [PrintBarcode::Label.new({ :number => id, :study => "", :suffix => suffix, :prefix => prefix })]
    begin
      unless printables.empty?
        barcode_printer.print_labels(printables)
      end
    rescue
      return false
    end
    true
  end
end
