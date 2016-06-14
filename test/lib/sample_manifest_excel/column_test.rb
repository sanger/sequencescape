require_relative '../../test_helper'

class ColumnTest < ActiveSupport::TestCase

  attr_reader :column, :sample, :range_list, :worksheet

  def setup
    @range_list = build(:range_list, options: { FactoryGirl.attributes_for(:validation)[:range_name] => FactoryGirl.attributes_for(:range)})
    @worksheet = Axlsx::Workbook.new.add_worksheet
  end

  def options
    { heading: "PUBLIC NAME", name: :public_name, value: "a value", type: :string, value: 10, number: 125,
      validation: FactoryGirl.attributes_for(:validation),
      conditional_formattings: {simple: FactoryGirl.attributes_for(:conditional_formatting), complex: FactoryGirl.attributes_for(:conditional_formatting_with_formula)}
    }
  end

  test "should have a heading" do
    assert_equal options[:heading], SampleManifestExcel::Column.new(options).heading
  end

  test "should not be valid without a heading" do
    refute SampleManifestExcel::Column.new(options.except(:heading)).valid?
  end

  test "should have a name" do
    assert_equal options[:name], SampleManifestExcel::Column.new(options).name
  end

  test "should not be valid without a name" do
    refute SampleManifestExcel::Column.new(options.except(:name)).valid?
  end

  test "should have a type" do
    assert_equal options[:type], SampleManifestExcel::Column.new(options).type
  end

  test "should have a value" do
    assert_equal options[:value], SampleManifestExcel::Column.new(options).value
    refute SampleManifestExcel::Column.new(options.except(:value)).value
  end

  test "should have an attribute value" do
    sample = build(:sample_with_well)
    assert_equal options[:value], SampleManifestExcel::Column.new(options).attribute_value(sample)
    assert_equal  SampleManifestExcel::Attributes.find(:sanger_sample_id).value(sample), SampleManifestExcel::Column.new(options.merge({name: :sanger_sample_id})).attribute_value(sample)
    refute  SampleManifestExcel::Column.new(options.except(:value)).attribute_value(sample)
  end

  test "should have a number" do
    assert_equal options[:number], SampleManifestExcel::Column.new(options).number
  end

  context "with no validation" do

    setup do
      @column = SampleManifestExcel::Column.new(options.except(:validation))
    end

    should "have an empty validation" do
      assert column.validation.empty?
    end

    should "have a range name" do
      refute column.range_name.nil?
    end

    should "update without any problems" do
      assert column.update(27, 150, range_list, worksheet).updated?
    end

  end

  context "with no conditional formattings" do

    setup do
      @column = SampleManifestExcel::Column.new(options.except(:conditional_formattings))
    end

    should "have empty conditional formattings" do
      assert column.conditional_formattings.empty?
    end

    should "update without any problems" do
      assert column.update(27, 150, range_list, worksheet).updated?
    end
  end

  context "#update with validation and formattings" do

    attr_reader :worksheet

    setup do
      @worksheet = Axlsx::Workbook.new.add_worksheet
      @column = SampleManifestExcel::Column.new(options).update(27, 150, range_list, worksheet)
    end

    should "work" do
      assert column.updated?
    end

    should "set the reference" do
      range = SampleManifestExcel::Range.new(first_column: column.number, first_row: 27, last_row: 150)
      assert_equal range, column.range
    end

    should "update the validation" do
      assert_equal range_list.find_by(column.range_name).absolute_reference, column.validation.formula1
      assert column.validation.saved?
    end

    should "update the conditional formatting" do
      assert_equal options[:conditional_formattings].length, column.conditional_formattings.count
      assert column.conditional_formattings.saved?
    end

  end

end