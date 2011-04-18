class SpikedBuffer < LibraryTube

  def index
    self.parents.each do |parent|
      next if parent.is_a?(SpikedBuffer) # todo befor next text as SpikedBuffer < LibraryTube
      return parent if parent.is_a?(LibraryTube)
    end
    nil
  end
  def master_index
    #TODO use holder instead of parent
    self.parents.each do |parent|
      if parent.is_a?(SpikedBuffer)
        return parent.master_index
      elsif parent.is_a?(LibraryTube)
        #  ugly
        if parent.parent.is_a?(TagInstance)
          return parent
        else
          return parent.parent
        end
      end
    end
    return nil
  end

  def percentage_of_index
    return nil unless index
    100*index.volume/volume
  end

  def transfer(volume)
    volume = volume.to_f
    index_volume_to_transfer = index.volume*volume/self.volume # to do before super which modifies self.volume
    new_asset = super(volume)
    #TODO : do it, and create index= method

    new_asset.add_parent(index.transfer(index_volume_to_transfer))

    return new_asset
  end
end
