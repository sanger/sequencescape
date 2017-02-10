# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

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
      @barcode = 2470000002799.to_s
      @human = 'ID2O'
    end

    should_eventually 'be splittable' do
      prefix, number, check = Barcode.split_barcode(@barcode)
      assert_equal '247', prefix
      assert_equal 2, number
      assert_equal '799', check
    end

    should 'have a human form' do
      assert_equal @human, Barcode.barcode_to_human(@barcode)
    end
  end

  context 'An invalid barcode' do
    setup do
      @barcode = 398002343284.to_s
    end

    should 'not have a human form' do
      assert_nil Barcode.barcode_to_human(@barcode)
    end
  end

  context 'A Generic Barcode' do
    setup do
      @barcode = 5018206206022.to_s
    end

    should 'have a valid EAN' do
      assert Barcode.check_EAN(@barcode)
    end
  end

  context 'A Generic Barcode' do
    setup do
      @barcode = 5018206206023.to_s
    end

    should 'not have an invalid EAN' do
      assert_equal false, Barcode.check_EAN(@barcode)
    end
  end

  context 'A number with more than 7 digits' do
    setup do
      @number = 12345678
    end
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
      @expected_machine_barcode = 4500001234757
    end

    should 'convert to the correct machine barcode' do
      assert_equal(@expected_machine_barcode, Barcode.human_to_machine_barcode(@human_readable_barcode))
    end

    should 'raise an exception with an invalid barcode' do
      assert_raise(Barcode::InvalidBarcode) do
        Barcode.human_to_machine_barcode(@invalid_human_barcode)
      end
    end
  end
end
