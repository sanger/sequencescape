class Equipment < ActiveRecord::Base

  validates_presence_of :name, :equipment_type
  before_validation :set_defaults
  after_create :update_barcode

  def set_defaults
    self.prefix||='XX'
  end

  def update_barcode
    self.ean13_barcode ||= Barcode.calculate_barcode(prefix, id)
    save!
  end

  def barcode_number
     Barcode.number_to_human(self.ean13_barcode)
  end

  def suffix
    Barcode.calculate_checksum(prefix, barcode_number)
  end

  def printables
    [PrintBarcode::Label.new({
      :number => barcode_number,
      :study => name,
      :suffix => suffix,
      :prefix => prefix,
      :type => "custom-labels",
      :label_description =>  name })]
  end

  def print(barcode_printer)
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
