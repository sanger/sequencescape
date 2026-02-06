# frozen_string_literal: true

require 'test_helper'

class LibraryTubeTest < ActiveSupport::TestCase
  context 'A Library tube' do
    setup { @library_tube = create(:library_tube) }

    context '#has_stock_asset?' do
      setup do
        @library_tube_with_stock_tube = create(:library_tube)
        @stock_library_tube = create(:stock_library_tube)
        @stock_library_tube.children << @library_tube_with_stock_tube
      end

      should "return false if it doesn't have a stock asset" do
        assert_not @library_tube.has_stock_asset?
      end

      should 'return true if it does have a stock asset' do
        assert_predicate @library_tube_with_stock_tube, :has_stock_asset?
      end
    end
  end
end
