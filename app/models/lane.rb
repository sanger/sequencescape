class Lane < Asset
  include LocationAssociation::Locatable
  named_scope :including_associations_for_json, { :include => [:uuid_object, :barcode_prefix ] }
  

  LIST_REASONS_NEGATIVE = [
    "Failed on yield but sufficient data for experiment",
    "Failed on quality but sufficient data for experiment",
    "Failed on adapter contamination but data sufficient for experiment"

  ]
  
  LIST_REASONS_POSITIVE = [
    "Data doesn't contain any of the expected organism",
    "Data doesn't reflect the experiment",
    "GC bias in data set",
    "Multiplex tag problems in data set",
    "Unsure data source"
  ]
  
  LIST_REASONS = [""] + LIST_REASONS_NEGATIVE + LIST_REASONS_POSITIVE
  
  extend Metadata
  has_metadata do
    attribute(:release_reason, :in => LIST_REASONS)
  end

  def spiked_in_buffer
    parents.each do |p|
      return p if p.is_a?(SpikedBuffer)
    end
    nil
  end

  def related_resources
    ['parents']
  end
  
  def self.render_class
    Api::LaneIO
  end
end
