module ModelExtensions::Plate
  def self.included(base)
    base.class_eval do
      named_scope :include_plate_purpose, :include => :plate_purpose
    end
  end

  def plate_purpose_or_stock_plate
    self.plate_purpose || PlatePurpose.find_by_name('Stock Plate')
  end
end
