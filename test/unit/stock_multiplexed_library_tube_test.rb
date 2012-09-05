require "test_helper"

class StockMultiplexedLibraryTubeTest < ActiveSupport::TestCase
  context "A stock multiplexed Library tube" do
    setup do
      @stock_multiplexed_library = Factory :stock_multiplexed_library_tube
    end

    context "#has_stock_asset?" do
      should "return false" do
        assert ! @stock_multiplexed_library.has_stock_asset?
      end
    end

    context "#is_a_stock_asset?" do
      should "return true" do
        assert @stock_multiplexed_library.is_a_stock_asset?
      end
    end
  end
end
