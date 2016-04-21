require 'test_helper'

class ColumnTest < ActiveSupport::TestCase

  class TestAttribute
    attr_accessor :name
    attr_reader :nested
    def initialize(name, value = nil)
      @name = name
      unless value.nil?
        @nested = NestedAttribute.new(value)
      end
    end

    class NestedAttribute
      attr_accessor :value
      def initialize(value)
        @value = value
      end
    end
  end

  attr_reader :column

  context "basic" do

    setup do
      @column = build :column
    end

    should "not be valid without a name" do
      column.heading = nil
      refute column.valid?
    end

    should "not be valid without a heading" do
      column.name = nil
      refute column.valid?
    end

    should "have a number" do
      assert_equal 0, column.number
      column.number = 10
      assert_equal 10, column.number
    end

    should "have a type" do
      assert_equal :string, column.type
      column.type = :number
      assert_equal :number, column.type
    end

    should "have a value" do
      refute column.value
      column.value = "a value"
      assert_equal "a value", column.value
    end

    should "locked or unlocked" do
      refute column.unlocked?
      column.unlocked = 999
      assert column.unlocked?
    end

    should "have an actual value" do
      refute column.actual_value(TestAttribute.new("My Attribute", "My Value"))
    end

    should "#set_number should set correct number to a column" do
      assert_equal 1, column.set_number(1).number
    end

    should "#add_reference should create position and set reference" do
      column.set_number(1).add_reference(10, 15)
      assert_equal SampleManifestExcel::Position.new(first_column: 1, first_row: 10, last_row: 15).reference, column.reference
      column.set_number(125).add_reference(27, 150)
      assert_equal SampleManifestExcel::Position.new(first_column: 125, first_row: 27, last_row: 150).reference, column.reference
    end
  end

  context "with attribute" do

    setup do
       @column = SampleManifestExcel::Column.new(heading: "PUBLIC NAME", name: :public_name, attribute: { test_attribute: Proc.new { |test_attribute| test_attribute.nested.value } } )
    end

    should "have an attribute" do
      assert_equal :test_attribute, column.attribute.keys.first
    end

    should "#attribute? should be true" do
      assert column.attribute?
    end

    should "retrieve the value" do
      assert_equal "My Value", column.attribute_value(TestAttribute.new("My Attribute", "My Value"))
    end

    should "retrieve the actual value" do
      assert_equal "My Value", column.actual_value(TestAttribute.new("My Attribute", "My Value"))
    end
  end

  context "with validation" do

    attr_reader :validation

    setup do
      @validation = {options: {type: :textLength, operator: :lessThanOrEqual, formula1: "20", showErrorMessage: true, errorStyle: :stop, errorTitle: "Supplier Sample Name", error: "Name must be a maximum of 20 characters in length", allowBlank: false}, range_name: :some_name}
      @column = SampleManifestExcel::Column.new(heading: "PUBLIC NAME", name: :public_name, validation: validation)
    end

    should "#validation? should be true" do
      assert column.validation?
    end

    should "have some validation" do
      assert_instance_of SampleManifestExcel::Validation, column.validation
    end

    should "#set_formula1 for validation" do
      range = build :range
      worksheet = build :worksheet
      range.set_absolute_reference(worksheet)
      column.set_formula1(range)
      assert range.absolute_reference, column.validation.options[:formula1]
    end

  end

end