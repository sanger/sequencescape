require "test_helper"

class MultiplexedLibraryTubeTest < ActiveSupport::TestCase
  context "A multiplexed Library tube" do
    setup do
      @multiplexed_library_tube = Factory :multiplexed_library_tube
    end
    context "#has_stock_asset?" do
      setup do
        @multiplexed_library_tube_with_stock_tube = Factory :multiplexed_library_tube
        @stock_multiplexed_library_tube = Factory :stock_multiplexed_library_tube
        @stock_multiplexed_library_tube.children << @multiplexed_library_tube_with_stock_tube
      end
      
      should "return false if it doesn't have a stock asset" do
        assert ! @multiplexed_library_tube.has_stock_asset?
      end
      
      should "return true if it does have a stock asset" do
        assert @multiplexed_library_tube_with_stock_tube.has_stock_asset?
      end
    end
    
    context "#new_stock_asset" do
      should "return a StockLibraryTube" do
        stock_multiplexed_library_tube = @multiplexed_library_tube.new_stock_asset
        assert stock_multiplexed_library_tube.kind_of?(StockMultiplexedLibraryTube)
      end
    end
  end
end
