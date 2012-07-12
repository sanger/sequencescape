class SpikedBuffer < LibraryTube
  # The index of a spiked buffer is the first parent library tube.  Note that this does not cover cases where
  # the sti_type is a derivative of LibraryTube, which is actually fine because SpikedBuffer is a LibraryTube
  # and we definitely don't want that in the list.
  has_one_as_child(:index, :conditions => { :sti_type => 'LibraryTube' })

  def library_prep?
    false
  end

  # Before the validations are run on creation we need to ensure that there is at least an aliquot of phiX
  # in this tube.
  before_validation(:on => :create) do |record|
    record.aliquots.build(:sample => record.class.phiX_sample) if record.aliquots.empty?
  end

  def self.phiX_sample
    @phiX_sample ||= Sample.find_by_name('phiX_for_spiked_buffers') or raise StandardError, "Cannot find phiX_for_spiked_buffers sample"
  end

  def percentage_of_index
    return nil unless index
    100*index.volume/volume
  end

  def transfer(volume)
    volume = volume.to_f
    index_volume_to_transfer = index.volume*volume/self.volume # to do before super which modifies self.volume

    super(volume).tap do |new_asset|
      new_asset.index = index.transfer(index_volume_to_transfer)
    end
  end
end
