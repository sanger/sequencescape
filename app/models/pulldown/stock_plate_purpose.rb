# Specialised implementation of the plate purpose for the stock plates that lead into the various
# pulldown pipelines.
class Pulldown::StockPlatePurpose < PlatePurpose
  # Returns the pulldown requests that lead out of this well
  def requests_for_pool(well)
    well.requests_as_source.where_is_a?(Pulldown::Requests::LibraryCreation)
  end
  private :requests_for_pool
end
