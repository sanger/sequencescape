require 'test_helper'

class ValidationTest < ActiveSupport::TestCase

  attr_reader :validation

  context "basic" do

    setup do
      @validation = build :validation
    end

    should "should have options" do
      assert_equal ({option1: 'value1', option2: 'value2', type: :smth, formula1: 'smth'}), validation.options
    end

    should "should know if range is required" do
      refute validation.range_required?
    end

  end

  context "with_range" do

    attr_reader :validation_with_range, :range

    setup do
      @validation = build :validation
      @validation_with_range = build :validation_with_range
      @range = build :range
      worksheet = build :worksheet
      range.set_absolute_reference(worksheet)
    end

    should "should have range" do
      assert_equal :some_range, validation_with_range.range_name
    end

    should "#set_formula1 should set range for fromula1" do
      validation_with_range.set_formula1(range)
      assert_equal range.absolute_reference, validation_with_range.options[:formula1]
      refute validation.set_formula1(range)
    end

    should "should know if range is required" do
      assert validation_with_range.range_required?
    end
  end

end