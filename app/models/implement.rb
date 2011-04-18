class Implement < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :barcode, :on => :update
  @@barcode_prefix = "LE"

  def generate_barcode
    raise Exception.new , "Can't generate barcode with a null ID" if id == 0
    b = Barcode.calculate_barcode(barcode_prefix, id)
    Barcode.barcode_to_human b
  end

  def barcode_prefix
    @@barcode_prefix
  end

  def human_barcode
    Barcode.barcode_to_human self.barcode
  end

  def save_and_generate_barcode
    ActiveRecord::Base.transaction do
      save and self.barcode = generate_barcode
      save
    end
  end
end
