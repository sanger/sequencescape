# Specialised implementation of the plate purpose for the stock plates that lead into the various
# pulldown pipelines.
class Pulldown::StockPlatePurpose < PlatePurpose
  def _pool_wells(wells)
    wells.pooled_as_source_by(Pulldown::Requests::LibraryCreation)
  end
  private :_pool_wells

  # The state of a pulldown stock plate is governed by whether it has any pulldown requests coming
  # out of it's wells.  If it does then it is considered 'passed', otherwise it is 'pending'
  def state_of(plate)
    plate.wells.requests_as_source_is_a?(Pulldown::Requests::LibraryCreation).empty? ? 'pending' : 'passed'
  end
end
