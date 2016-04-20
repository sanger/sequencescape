require 'test_helper'

class ValidationTest < ActiveSupport::TestCase

  attr_reader :validation, :range

  def setup
    @validation = SampleManifestExcel::Validation.new({option1: 'value1', option2: 'value2', type: :list, formula1: 'smth'}, :some_range)
    @range = build :range
  end

  test "should have options" do
    assert_equal ({option1: 'value1', option2: 'value2', type: :list, formula1: 'smth'}), validation.options
  end

  test "should have range" do
    assert_equal :some_range, validation.range_name
  end

  test "#set_formula1 should set range for fromula1" do
    worksheet = build :worksheet
    range.set_absolute_reference(worksheet)
    validation.set_formula1(range)
    assert_equal range.absolute_reference, validation.options[:formula1]
  end 

end