# frozen_string_literal: true
class Search::FindLotByLotNumber < Search
  def scope(criteria)
    Lot.with_lot_number(criteria['lot_number'])
  end
end
