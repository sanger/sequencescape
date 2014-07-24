require "test_helper"

class StockSampleTubeTest < ActiveSupport::TestCase
  context "A stock sample tube" do
    setup do
      @stock_sample = Factory :stock_sample_tube
    end

    context "#has_stock_asset?" do
      should "return false" do
        assert ! @stock_sample.has_stock_asset?
      end
    end

    context "#is_a_stock_asset?" do
      should "return true" do
        assert @stock_sample.is_a_stock_asset?
      end
    end
  end
end
