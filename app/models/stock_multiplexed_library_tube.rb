# frozen_string_literal: true
class StockMultiplexedLibraryTube < Tube # rubocop:todo Style/Documentation
  include Asset::Stock

  def stock_wells
    purpose.stock_wells(self)
  end

  def sibling_tubes
    purpose.sibling_tubes(self)
  end
end
