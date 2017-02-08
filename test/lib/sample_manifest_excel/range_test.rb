require 'test_helper'

class RangeTest < ActiveSupport::TestCase
  attr_reader :range, :options

  def setup
    @options = ['option1', 'option2', 'option3']
  end

  test 'should be comparable' do
    attributes = { options: options, first_column: 4, first_row: 5, last_column: 8, last_row: 10, worksheet_name: 'Sheet1' }
    assert_equal SampleManifestExcel::Range.new(attributes), SampleManifestExcel::Range.new(attributes)
    refute_equal SampleManifestExcel::Range.new(attributes), SampleManifestExcel::Range.new(attributes.except(:last_row))
  end

  context 'with options' do
    setup do
      @range = SampleManifestExcel::Range.new(options: options, first_row: 4)
    end

    should 'have some options' do
      assert_equal options, range.options
    end

    should 'have a first row' do
      assert_equal 4, range.first_row
    end

    should 'set the first column' do
      assert_equal 1, range.first_column
    end

    should 'set the last column' do
      assert_equal 3, range.last_column

      assert_equal 6, SampleManifestExcel::Range.new(options: options, first_column: 4, first_row: 4).last_column
    end

    should 'have a first_cell' do
      assert_equal SampleManifestExcel::Cell.new(range.first_row, range.first_column), range.first_cell
    end

    should 'have a last_cell' do
      assert_equal SampleManifestExcel::Cell.new(range.last_row, range.last_column), range.last_cell
    end

    should 'have a first cell reference' do
      assert_equal range.first_cell.reference, range.first_cell_reference
    end

    should 'set the reference' do
      assert_equal "#{range.first_cell.reference}:#{range.last_cell.reference}", range.reference
    end

    should 'set the fixed reference' do
      assert_equal "#{range.first_cell.fixed}:#{range.last_cell.fixed}", range.fixed_reference
    end

    should '#references should return first_cell reference, reference, fixed_reference and absolute_reference' do
      assert_equal({ first_cell_reference: range.first_cell_reference,
                     reference: range.reference, fixed_reference: range.fixed_reference,
                     absolute_reference: range.absolute_reference }, range.references)
    end
  end

  context 'without first row' do
    setup do
      @range = SampleManifestExcel::Range.new(options: options)
    end

    should 'not be valid' do
      refute range.valid?
    end

    should 'not have a first cell' do
      refute range.first_cell
    end

    should 'not have a last cell' do
      refute range.last_cell
    end
  end

  context 'without options' do
    setup do
      @range = SampleManifestExcel::Range.new(first_row: 10, last_row: 15, first_column: 3, last_column: 60)
    end

    should 'have some empty options' do
      assert range.options.empty?
    end

    should 'have a first row' do
      assert_equal 10, range.first_row
    end

    should 'have a first column' do
      assert_equal 3, range.first_column
    end

    should 'have a last column' do
      assert_equal 60, range.last_column
    end

    should 'have a first_cell' do
      assert_equal SampleManifestExcel::Cell.new(range.first_row, range.first_column), range.first_cell
    end

    should 'have a last_cell' do
      assert_equal SampleManifestExcel::Cell.new(range.last_row, range.last_column), range.last_cell
    end

    should 'set the fixed_reference' do
      assert_equal "#{range.first_cell.reference}:#{range.last_cell.reference}", range.reference
    end

    should 'set the fixed reference' do
      assert_equal "#{range.first_cell.fixed}:#{range.last_cell.fixed}", range.fixed_reference
    end

    should 'have an absolute reference' do
      assert_equal range.fixed_reference, range.absolute_reference
    end

    should '#set_worksheet_name should set worksheet name and modify absolute reference' do
      range.set_worksheet_name 'Sheet1'
      assert_equal 'Sheet1', range.worksheet_name
      assert_equal "#{range.worksheet_name}!#{range.fixed_reference}", range.absolute_reference
    end

    context 'without last row' do
      setup do
        @range = SampleManifestExcel::Range.new(first_row: 15, first_column: 5, last_column: 15)
      end

      should 'set last row to first row' do
        assert_equal 15, range.last_row
      end
    end

    context 'without last column' do
      setup do
        @range = SampleManifestExcel::Range.new(first_row: 14, last_row: 25, first_column: 33)
      end

      should 'set last column to first column' do
        assert_equal 33, range.last_column
      end
    end

    context 'with worksheet name' do
      setup do
        @range = SampleManifestExcel::Range.new(first_row: 10, last_row: 15, first_column: 3, last_column: 60, worksheet_name: 'Sheet1')
      end

      should 'set worksheet name' do
        assert_equal 'Sheet1', range.worksheet_name
      end

      should 'set absolute reference' do
        assert_equal "Sheet1!#{range.fixed_reference}", range.absolute_reference
      end
    end
  end
end
