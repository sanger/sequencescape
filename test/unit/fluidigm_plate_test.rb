# frozen_string_literal: true

require 'test_helper'

class FluidigmPlateTest < ActiveSupport::TestCase
  context 'A 96:96 Fluidigm Plate' do
    setup do
      barcode = build(:plate_barcode)
      PlateBarcode.stubs(:create_barcode).returns(barcode)
      @plate = create(:fluidigm_96_purpose).create!(barcode:)
    end

    should 'have 96 wells' do
      assert_equal 96, @plate.wells.count
      assert_equal 96, @plate.size
    end

    should 'have wells named sequentially in rows with prefix S' do
      @plate.wells.in_row_major_order.each_with_index { |w, i| assert_operator 'S%02d', :%, i, w.map_description }
    end

    should 'be 6*16' do
      assert_equal 'S07', @plate.wells.in_column_major_order[1].map_description
    end
  end

  context 'A 192:24 Fluidigm Plate' do
    setup do
      barcode = build(:plate_barcode)
      PlateBarcode.stubs(:create_barcode).returns(barcode)
      @plate = create(:fluidigm_192_purpose).create!(barcode:)
    end

    should 'have 192 wells' do
      assert_equal 192, @plate.wells.count
      assert_equal 192, @plate.size
    end

    should 'have wells named sequentially in rows with prefix S' do
      @plate.wells.in_row_major_order.each_with_index { |w, i| assert_operator 'S%03d', :%, i, w.map_description }
    end

    should 'be 12*16' do
      assert_equal 'S013', @plate.wells.in_column_major_order[1].map_description
    end
  end
end
