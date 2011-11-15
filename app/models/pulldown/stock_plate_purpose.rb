# Specialised implementation of the plate purpose for the stock plates that lead into the various
# pulldown pipelines.
class Pulldown::StockPlatePurpose < PlatePurpose
  def _pool_wells(wells)
    wells.pooled_as_source_by(Pulldown::Requests::LibraryCreation)
  end
  private :_pool_wells

  # The state of a pulldown stock plate is governed by the presence of pulldown requests combined
  # with the aliquots.  Basically every well that has stuff in it should have a pulldown request
  # for the plate to be 'passed', otherwise it is 'pending'.  An empty plate is also considered
  # to be pending.
  def state_of(plate)
    state_and_requests = plate.wells.map { |well| [ !well.aliquots.empty?, well.requests_as_source.where_is_a?(Pulldown::Requests::LibraryCreation).empty? ] }
    return 'pending' if state_and_requests.all? { |full_well, _| not full_well }   # Pending if all of the wells are empty
    state_and_requests.any? { |full_well, no_requests| full_well and no_requests } ? 'pending' : 'passed'
  end
end
