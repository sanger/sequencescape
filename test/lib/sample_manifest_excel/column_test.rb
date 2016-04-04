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
      @column = SampleManifestExcel::Column.new(heading: "PUBLIC NAME", name: :public_name, value: "a value")
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
      assert_equal "a value", column.value
    end

    should "#set_position should set correct position to a column" do
      assert_equal 1, column.set_position(1).position
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
      test_attribute = TestAttribute.new("My Attribute", "My Value")
      assert_equal "My Value", column.attribute_value(test_attribute)
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
      assert_instance_of Axlsx::DataValidation, column.validation
      assert_equal validation[:type], column.validation.type
      assert_equal validation[:operator], column.validation.operator
      assert_equal validation[:formula1], column.validation.formula1
      assert_equal validation[:showErrorMessage], column.validation.showErrorMessage
      assert_equal validation[:errorStyle], column.validation.errorStyle
      assert_equal validation[:errorTitle], column.validation.errorTitle
      assert_equal validation[:error], column.validation.error
      refute column.validation.prompt
    end
  end

end