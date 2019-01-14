require 'test_helper'

class MultiplexedLibraryTubeTest < ActiveSupport::TestCase
  context 'A multiplexed Library tube' do
    setup do
      @multiplexed_library_tube = create :multiplexed_library_tube
    end
    context '#has_stock_asset?' do
      setup do
        @multiplexed_library_tube_with_stock_tube = create :multiplexed_library_tube
        @stock_multiplexed_library_tube = create :stock_multiplexed_library_tube
        @stock_multiplexed_library_tube.children << @multiplexed_library_tube_with_stock_tube
      end

      should "return false if it doesn't have a stock asset" do
        assert_not @multiplexed_library_tube.has_stock_asset?
      end

      should 'return true if it does have a stock asset' do
        assert @multiplexed_library_tube_with_stock_tube.has_stock_asset?
      end
    end

    context '#create_stock_asset!' do
      context 'straight creation' do
        setup do
          @stock = @multiplexed_library_tube.create_stock_asset!
        end

        should 'create a StockLibraryTube' do
          assert @stock.is_a?(StockMultiplexedLibraryTube)
        end

        should 'mark the name correctly' do
          assert_equal("(s) #{@multiplexed_library_tube.name}", @stock.name)
        end

        should 'have a different barcode' do
          assert_not_equal(@multiplexed_library_tube.barcode_number, @stock.barcode_number)
        end
      end

      context 'should allow overriding of attributes' do
        setup do
          @custom_barcode = generate(:barcode_number).to_s
          @stock = @multiplexed_library_tube.create_stock_asset!(name: 'Foo', barcode: @custom_barcode)
        end

        should 'use the specified name' do
          assert_equal 'Foo', @stock.name
        end

        should 'set the barcode' do
          assert_equal @custom_barcode, @stock.barcode_number.to_s
        end
      end
    end
  end
end
