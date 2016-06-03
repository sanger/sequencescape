require_relative '../../test_helper'

class ColumnTest < ActiveSupport::TestCase

  attr_reader :column, :sample

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

    should "have an attribute value" do
      refute column.attribute_value(build(:sample))
      column.value = "a value"
      assert_equal "a value", column.attribute_value(build(:sample))
    end

    should "#set_number should set correct number to a column" do
      assert_equal 1, column.set_number(1).number
    end

    should "#add_reference should create position and set reference" do
      column.set_number(1).add_reference(10, 15)
      assert_equal SampleManifestExcel::Range.new(first_column: 1, first_row: 10, last_row: 15).reference, column.reference
      column.set_number(125).add_reference(27, 150)
      assert_equal SampleManifestExcel::Range.new(first_column: 125, first_row: 27, last_row: 150).reference, column.reference
      assert_equal SampleManifestExcel::Range.new(first_column: 125, first_row: 27, last_row: 150).first_cell_relative_reference, column.first_cell_relative_reference
    end
  end

  context "with known attribute" do

    attr_reader :sample

    setup do
       @column = SampleManifestExcel::Column.new(heading: "PUBLIC NAME", name: :sanger_sample_id)
       @sample = build(:sample)
    end

    should "retrieve the value" do
      assert_equal SampleManifestExcel::Attributes.find(:sanger_sample_id).value(sample), column.attribute_value(sample)
    end

  end

  context "with validation" do

    attr_reader :validation

    setup do
      @column = build :column_with_validation
    end

    should "#validation? should be true" do
      assert column.validation?
    end

    should "have some validation" do
      assert_instance_of SampleManifestExcel::Validation, column.validation
    end

    should "#prepare_validation should prepare validation" do
      range = build :range
      column.prepare_validation(range)
      assert range.absolute_reference, column.validation.options[:formula1]
    end

  end

  context "with conditional formatting rules" do
    attr_reader :raw_column, :ranges, :validation, :styles, :range

    setup do
      @column = SampleManifestExcel::Column.new(validation: FactoryGirl.attributes_for(:validation), conditional_formattings: {simple: FactoryGirl.attributes_for(:conditional_formatting), complex: FactoryGirl.attributes_for(:conditional_formatting_with_formula)})
      column.set_number(3).add_reference(10, 15)
    end

    should "have conditional formatting rules" do
      assert_equal 2, column.conditional_formattings.count
    end

    should "#prepare_conditional_formatting_rules should prepare all rules" do
      column.prepare_conditional_formattings(Axlsx::Workbook.new, build(:range))
      assert column.conditional_formattings.each_item.first.styled?
    end

  end

  context "complicated column" do

    setup do
      style =build :style
      @styles = {unlock: style, style_name: style, style_name_2: style}
      @raw_column = build :column_with_validation_and_conditional_formatting
      @ranges = build(:range_list, options: YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_validation_ranges.yml"))))
    end

    should "prepare column" do
      refute raw_column.range
      raw_column.prepare_with(10, 15, styles, ranges)
      assert raw_column.range
      assert_equal ranges.find_by(:gender).absolute_reference, raw_column.validation.options[:formula1]
    end

  end

end