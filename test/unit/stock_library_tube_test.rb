require "test_helper"

class StockLibraryTubeTest < ActiveSupport::TestCase
  context "A stock Library tube" do
    setup do
      @stock_library = Factory :stock_library_tube
    end

    context "#has_stock_asset?" do
      should "return false" do
        assert ! @stock_library.has_stock_asset?
      end
    end

    context "#is_a_stock_asset?" do
      should "return true" do
        assert @stock_library.is_a_stock_asset?
      end
    end
  end
end
