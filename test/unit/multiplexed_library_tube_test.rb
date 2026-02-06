# frozen_string_literal: true

require 'test_helper'

class MultiplexedLibraryTubeTest < ActiveSupport::TestCase
  context 'A multiplexed Library tube' do
    setup { @multiplexed_library_tube = create(:multiplexed_library_tube) }
    context '#has_stock_asset?' do
      setup do
        @multiplexed_library_tube_with_stock_tube = create(:multiplexed_library_tube)
        @stock_multiplexed_library_tube = create(:stock_multiplexed_library_tube)
        @stock_multiplexed_library_tube.children << @multiplexed_library_tube_with_stock_tube
      end

      should "return false if it doesn't have a stock asset" do
        assert_not @multiplexed_library_tube.has_stock_asset?
      end

      should 'return true if it does have a stock asset' do
        assert_predicate @multiplexed_library_tube_with_stock_tube, :has_stock_asset?
      end
    end
  end
end
