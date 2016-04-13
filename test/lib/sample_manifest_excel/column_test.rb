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
      @column = SampleManifestExcel::Column.new(heading: "PUBLIC NAME", name: :public_name)
    end

    should "not be valid without a name" do
      column.heading = nil
      refute column.valid?
    end

    should "not be valid without a heading" do
      column.name = nil
      refute column.valid?
    end

    should "have a position" do
      assert_equal 0, column.position
      column.position = 10
      assert_equal 10, column.position
    end

    should "have a type" do
      assert_equal :string, column.type
      column.type = :number
      assert_equal :number, column.type
    end

    should "have a value" do
      assert_equal "", column.value
      column.value = "a value"
      assert_equal "a value", column.value
    end

    should "locked or unlocked" do
      refute column.unlocked?
      column.unlocked = 999
      assert column.unlocked?
    end

    should "have an actual value" do
      assert_equal "", column.actual_value(TestAttribute.new("My Attribute", "My Value"))
    end

    should "#set_position should set correct position to a column" do
      assert_equal 1, column.set_position(1).position
    end

    should "#position_alpha should return position as letters of alphabet" do
      refute column.position_alpha
      assert_equal "A", column.set_position(1).position_alpha
      assert_equal "Z", column.set_position(26).position_alpha
      assert_equal "AA", column.set_position(27).position_alpha
      assert_equal "AZ", column.set_position(52).position_alpha
      assert_equal "BA", column.set_position(53).position_alpha
      assert_equal "ZZ", column.set_position(702).position_alpha
    end

    should "#add_range should set position to the first cell, last cell and range" do
      column.set_position(1).add_range(10, 15)
      assert_equal "A10", column.first_cell
      assert_equal "A15", column.last_cell
      assert_equal "A10:A15", column.range
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
      @validation = {type: :textLength, operator: :lessThanOrEqual, formula1: "20", showErrorMessage: true, errorStyle: :stop, errorTitle: "Supplier Sample Name", error: "Name must be a maximum of 20 characters in length", allowBlank: false}
      @column = SampleManifestExcel::Column.new(heading: "PUBLIC NAME", name: :public_name, validation: validation)
    end

    should "#validation? should be true" do
      assert column.validation?
    end

    should "have some validation" do
      assert_equal validation, column.validation
    end

  end

end