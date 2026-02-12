# frozen_string_literal: true

require 'test_helper'

class StockLibraryTubeTest < ActiveSupport::TestCase
  context 'A stock Library tube' do
    setup { @stock_library = create(:stock_library_tube) }

    context '#has_stock_asset?' do
      should 'return false' do
        assert_not @stock_library.has_stock_asset?
      end
    end

    context '#is_a_stock_asset?' do
      should 'return true' do
        assert_predicate @stock_library, :is_a_stock_asset?
      end
    end
  end
end
