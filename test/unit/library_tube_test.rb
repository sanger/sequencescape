require "test_helper"

class LibraryTubeTest < ActiveSupport::TestCase
  context "A Library tube" do
    context "#has_stock_asset?" do
      setup do
        @library_tube = Factory :library_tube
        @library_tube_with_stock_tube = Factory :library_tube
        @stock_library_tube = Factory :stock_library_tube
        @stock_library_tube.children << @library_tube_with_stock_tube
      end
      
      should "return false if it doesn't have a stock asset" do
        assert ! @library_tube.has_stock_asset?
      end
      
      should "return true if it does have a stock asset" do
        assert @library_tube_with_stock_tube.has_stock_asset?
      end
    end
    
    context "#new_stock_asset" do
      setup do
        @library_tube = Factory :library_tube
      end

      should "return a StockLibraryTube" do
        stock_library_tube = @library_tube.new_stock_asset
        assert stock_library_tube.kind_of?(StockLibraryTube)
      end
    end
  end
end
