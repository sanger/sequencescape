# A table allowing for the generation of unique equipment barcodes.
# Seems to perform an almost identical function to the unused {Implement}.
# No dependencies in the rest of the code, and mainly just used to ensure uniqueness of
# equipment barcodes.
class Equipment < ApplicationRecord
  validates :name, :equipment_type, presence: true
  before_validation :set_defaults
  after_create :update_barcode

  def set_defaults
    self.prefix ||= 'XX'
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
end
