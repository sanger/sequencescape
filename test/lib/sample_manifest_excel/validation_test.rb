require 'test_helper'

class ValidationTest < ActiveSupport::TestCase

  attr_reader :validation, :range

  def setup
    @validation = SampleManifestExcel::Validation.new({options: {option1: 'value1', option2: 'value2', type: :list, formula1: 'smth'}, range_name: :some_range})
    @range = build :range
  end

  test "should have options" do
    assert_equal ({option1: 'value1', option2: 'value2', type: :list, formula1: 'smth'}), validation.options
  end

  test "should have range" do
    assert_equal :some_range, validation.range_name
  end

  test "#set_formula1 should set range for fromula1 if required" do
    worksheet = build :worksheet
    range.set_absolute_reference(worksheet)
    validation.set_formula1(range)
    assert_equal range.absolute_reference, validation.options[:formula1]
    validation_without_range = SampleManifestExcel::Validation.new({options: {option1: 'value1', option2: 'value2', type: :list, formula1: 'smth'}})
    refute validation_without_range.set_formula1(range)
  end 

  test "should know if range is required" do
    assert validation.range_required?
    validation = SampleManifestExcel::Validation.new({options: {option1: 'value1', option2: 'value2', type: :list, formula1: 'smth'}})
    refute validation.range_required?
  end

end