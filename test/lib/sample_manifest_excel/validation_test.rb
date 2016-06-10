require_relative '../../test_helper'

class ValidationTest < ActiveSupport::TestCase

  attr_reader :validation, :options, :range

  def setup
    @options = {option1: 'value1', option2: 'value2', type: :whole, formula1: 'smth'}
    @range = build(:range)
  end

  test "should not be valid without options" do
    refute SampleManifestExcel::Validation.new.valid?
  end

  context "without range name" do

    setup do
      @validation = SampleManifestExcel::Validation.new(options: options)
    end

    should "should have options" do
      assert_equal options.with_indifferent_access, validation.options
    end

    should "not have a range name" do
      refute validation.range_name
    end

    should "should not add a range" do
      validation.update(range: range)
      refute_equal range.absolute_reference, validation.formula1 
    end

  end

  context "with range name" do

    setup do
      @validation = SampleManifestExcel::Validation.new(options: options, range_name: :a_range)
    end

    should "should have a range name" do
      assert_equal :a_range, validation.range_name
    end

    should "#update should set formula1" do
      validation.update(range: range)
      assert_equal range.absolute_reference, validation.formula1
    end

  end

  context "with worksheet" do

    attr_reader :worksheet

    setup do
      @worksheet = Axlsx::Package.new.workbook.add_worksheet
      @range = build(:range)
      @validation = SampleManifestExcel::Validation.new(options: options)
    end

    should "have options" do
      assert_equal options.with_indifferent_access, validation.options
    end

    should "add validation to the worksheet" do
      validation.update(reference: range.reference, worksheet: worksheet)
      validations = worksheet.send(:data_validations)
      assert_equal 1, validations.count
      assert_equal range.reference, validations.first.sqref 
    end

  end

end