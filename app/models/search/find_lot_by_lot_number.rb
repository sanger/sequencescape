# frozen_string_literal: true
class Search::FindLotByLotNumber < Search # rubocop:todo Style/Documentation
  def scope(criteria)
    Lot.with_lot_number(criteria['lot_number'])
  end
end
