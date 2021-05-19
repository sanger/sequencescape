# frozen_string_literal: true

require 'test_helper'

class LibraryTubeTest < ActiveSupport::TestCase
  context 'A Library tube' do
    setup { @library_tube = create :library_tube }

    context '#has_stock_asset?' do
      setup do
        @library_tube_with_stock_tube = create :library_tube
        @stock_library_tube = create :stock_library_tube
        @stock_library_tube.children << @library_tube_with_stock_tube
      end

      should "return false if it doesn't have a stock asset" do
        assert_not @library_tube.has_stock_asset?
      end

      should 'return true if it does have a stock asset' do
        assert @library_tube_with_stock_tube.has_stock_asset?
      end
    end

    context '#create_stock_asset!' do
      context 'straight creation' do
        setup { @stock = @library_tube.create_stock_asset! }

        should 'create a StockLibraryTube' do
          assert @stock.is_a?(StockLibraryTube)
        end

        should 'mark the name correctly' do
          assert_equal("(s) #{@library_tube.name}", @stock.name)
        end

        should 'have a different barcode' do
          assert_not_equal(@library_tube.human_barcode, @stock.human_barcode)
        end
      end

      context 'should allow overriding of attributes' do
        setup { @stock = @library_tube.create_stock_asset!(name: 'Foo', barcode: '1111') }

        should 'use the specified name' do
          assert_equal 'Foo', @stock.name
        end

        should 'set the barcode' do
          assert_equal '1111', @stock.barcode_number
        end
      end
    end
  end
end
