# Specialised implementation of the plate purpose for the stock plates that lead into the various
# pulldown pipelines.
class Pulldown::StockPlatePurpose < PlatePurpose
  def _pool_wells(wells)
    wells.pooled_as_source_by(Pulldown::Requests::LibraryCreation)
  end
  private :_pool_wells
end
