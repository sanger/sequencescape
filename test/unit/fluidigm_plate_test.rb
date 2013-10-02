require "test_helper"

class FluidigmPlateTest < ActiveSupport::TestCase
  context "A 96:96 Fluidigm Plate" do
    setup do
      @plate = PlatePurpose.find_by_name('Fluidigm 96-96').create!(:barcode=>Factory.next(:barcode_number) )
    end

    should "have 96 wells" do
      assert_equal 96, @plate.wells.count
      assert_equal 96, @plate.size
    end

    should "have wells named sequentially in rows with prefix S" do
      @plate.wells.in_row_major_order.each_with_index do |w,i|
        assert "S#{i}", w.map_description
      end
    end

    should 'be 6*16' do
      assert_equal 'S7', @plate.wells.in_column_major_order[1].map_description
    end
  end

  context "A 192:24 Fluidigm Plate" do
    setup do
      @plate = PlatePurpose.find_by_name('Fluidigm 192-24').create!(:barcode=>Factory.next(:barcode_number) )
    end

    should "have 192 wells" do
      assert_equal 192, @plate.wells.count
      assert_equal 192, @plate.size
    end

    should "have wells named sequentially in rows with prefix S" do
      @plate.wells.in_row_major_order.each_with_index do |w,i|
        assert "S#{i}", w.map_description
      end
    end

    should 'be 12*16' do
      assert_equal 'S13', @plate.wells.in_column_major_order[1].map_description
    end

  end
end
