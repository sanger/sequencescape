class Lane < Aliquot::Receptacle
  include Api::LaneIO::Extensions
  include LocationAssociation::Locatable

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

  has_one_as_child(:spiked_in_buffer, :conditions => { :sti_type => 'SpikedBuffer' })
end
