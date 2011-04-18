module ModelExtensions::Asset
  def self.included(base)
    base.class_eval do
      named_scope :include_barcode_prefix, :include => :barcode_prefix
    end
  end
end
