# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

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
        assert !@multiplexed_library_tube.has_stock_asset?
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
          assert_not_equal(@multiplexed_library_tube.barcode, @stock.barcode)
        end
      end

      context 'should allow overriding of attributes' do
        setup do
          @stock = @multiplexed_library_tube.create_stock_asset!(name: 'Foo', barcode: '1111')
        end

        should 'use the specified name' do
          assert_equal 'Foo', @stock.name
        end

        should 'set the barcode' do
          assert_equal '1111', @stock.barcode
        end
      end
    end
  end
end
