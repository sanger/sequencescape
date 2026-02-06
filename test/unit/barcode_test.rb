# frozen_string_literal: true

require 'test_helper'

class BarcodeTest < ActiveSupport::TestCase
  context 'A prefix and a number' do
    setup do
      # Input
      @prefix = 'PR'
      @number = 1234

      # Expected results
      @checksum = 'K'
      @human = "#{@prefix}#{@number}#{@checksum}"
    end

    should 'have a checksum' do
      assert_equal @checksum, Barcode.calculate_checksum(@prefix, @number)
    end

    should 'generate a barcode' do
      b = Barcode.calculate_barcode(@prefix, @number)

      assert b
      assert_equal 13, b.to_s.size
    end

    should 'generate a human barcode' do
      b = Barcode.calculate_barcode(@prefix, @number)
      human = Barcode.barcode_to_human b

      assert human
      assert_equal @human, human
    end
  end

  context 'A valid barcode' do
    setup do
      @barcode = 2_470_000_002_799.to_s
      @human = 'ID2O'
    end

    should 'have a human form' do
      assert_equal @human, Barcode.barcode_to_human(@barcode)
    end
  end

  context 'An invalid barcode' do
    setup { @barcode = 398_002_343_284.to_s }

    should 'not have a human form' do
      assert_nil Barcode.barcode_to_human(@barcode)
    end
  end

  context 'A Generic Barcode' do
    setup { @barcode = 5_018_206_206_022.to_s }

    should 'have a valid EAN' do
      assert Barcode.check_EAN(@barcode)
    end
  end

  context 'A Generic Barcode' do
    setup { @barcode = 5_018_206_206_023.to_s }

    should 'not have an invalid EAN' do
      assert_equal false, Barcode.check_EAN(@barcode)
    end
  end

  context 'A number with more than 7 digits' do
    setup { @number = 12_345_678 }

    should 'raise a error' do
      assert_raise ArgumentError do
        Barcode.calculate_barcode 'DN', @number
      end
    end
  end

  context 'A human readable barcode' do
    setup do
      @human_readable_barcode = 'PR1234K'
      @invalid_human_barcode = 'QQ12345A'
      @expected_machine_barcode = 4_500_001_234_757
    end

    should 'convert to the correct machine barcode' do
      assert_equal(@expected_machine_barcode, Barcode.human_to_machine_barcode(@human_readable_barcode))
    end

    should 'raise an exception with an invalid barcode' do
      assert_raise(SBCF::BarcodeError) { Barcode.human_to_machine_barcode(@invalid_human_barcode) }
    end
  end
end
