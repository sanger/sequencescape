require 'test_helper'

class ColumnTest < ActiveSupport::TestCase
  attr_reader :column, :sample, :range_list, :worksheet

  def setup
    @range_list = build(:range_list, options: { FactoryGirl.attributes_for(:validation)[:range_name] => FactoryGirl.attributes_for(:range) })
    @worksheet = Axlsx::Workbook.new.add_worksheet
  end

  def options
    { heading: 'PUBLIC NAME', name: :public_name, type: :string, value: 10, number: 125, attribute: :barcode,
      validation: FactoryGirl.attributes_for(:validation),
      conditional_formattings: { simple: FactoryGirl.attributes_for(:conditional_formatting), complex: FactoryGirl.attributes_for(:conditional_formatting_with_formula) }
    }
  end

  test 'should have a heading' do
    assert_equal options[:heading], SampleManifestExcel::Column.new(options).heading
  end

  test 'should not be valid without a heading' do
    refute SampleManifestExcel::Column.new(options.except(:heading)).valid?
  end

  test 'should have a name' do
    assert_equal options[:name], SampleManifestExcel::Column.new(options).name
  end

  test 'should not be valid without a name' do
    refute SampleManifestExcel::Column.new(options.except(:name)).valid?
  end

  test 'should have a type' do
    assert_equal options[:type], SampleManifestExcel::Column.new(options).type
  end

  test 'should have a value' do
    assert_equal options[:value], SampleManifestExcel::Column.new(options).value
    refute SampleManifestExcel::Column.new(options.except(:value)).value
  end

  test 'should be comparable' do
    assert_equal SampleManifestExcel::Column.new(options), SampleManifestExcel::Column.new(options)
    refute_equal SampleManifestExcel::Column.new(options), SampleManifestExcel::Column.new(options.merge(heading: 'SOME OTHER NAME'))
  end

  # test "should have an attribute value" do
  #   sample = build(:sample_with_well)
  #   assert_equal options[:value], SampleManifestExcel::Column.new(options).attribute_value(sample)
  #   assert_equal  SampleManifestExcel::Attributes.find(:sanger_sample_id).value(sample), SampleManifestExcel::Column.new(options.merge({name: :sanger_sample_id})).attribute_value(sample)
  #   refute  SampleManifestExcel::Column.new(options.except(:value)).attribute_value(sample)
  # end

  test 'should have an attribute value' do
    detail = { barcode: 'barcode', sanger_id: 'sanger_id', position: 'position' }
    assert_equal detail[:barcode], SampleManifestExcel::Column.new(options).attribute_value(detail)
    assert_equal options[:value], SampleManifestExcel::Column.new(options.except(:attribute)).attribute_value(detail)
    refute SampleManifestExcel::Column.new(options.except(:value, :attribute)).attribute_value(detail)
  end

  test 'should have a number' do
    assert_equal options[:number], SampleManifestExcel::Column.new(options).number
  end

  context 'with no validation' do
    setup do
      @column = SampleManifestExcel::Column.new(options.except(:validation))
    end

    should 'have an empty validation' do
      assert column.validation.empty?
    end

    should 'have a range name' do
      refute column.range_name.nil?
    end

    should 'update without any problems' do
      assert column.update(27, 150, range_list, worksheet).updated?
    end
  end

  context 'with no conditional formattings' do
    setup do
      @column = SampleManifestExcel::Column.new(options.except(:conditional_formattings))
    end

    should 'have empty conditional formattings' do
      assert column.conditional_formattings.empty?
    end

    should 'update without any problems' do
      assert column.update(27, 150, range_list, worksheet).updated?
    end
  end

  context '#update with validation and formattings' do
    attr_reader :worksheet, :dupped, :range

    setup do
      @worksheet = Axlsx::Workbook.new.add_worksheet
      @column = SampleManifestExcel::Column.new(options)
      @range = SampleManifestExcel::Range.new(first_column: column.number, first_row: 27, last_row: 150)
      @dupped = column.dup
      column.update(27, 150, range_list, worksheet)
    end

    should 'work' do
      assert column.updated?
    end

    should 'set the reference' do
      assert_equal range, column.range
    end

    should 'update the validation' do
      assert_equal range_list.find_by(column.range_name).absolute_reference, column.validation.formula1
      assert worksheet.data_validation_rules.all? { |rule| rule.sqref == column.range.reference }
      assert column.validation.saved?
    end

    should 'update the conditional formatting' do
      assert_equal options[:conditional_formattings].length, column.conditional_formattings.count
      assert column.conditional_formattings.saved?
    end

    should 'duplicate correctly' do
      refute_equal range, dupped.range
      refute dupped.validation.saved?
      refute dupped.conditional_formattings.saved?
    end
  end

  # TODO: Need to improve way keys are found to reduce brittleness of tests.
  # would break if column names changed.
  context 'argument builder' do
    include SampleManifestExcel::Helpers

    attr_reader :columns, :defaults

    setup do
      folder = File.join('test', 'data', 'sample_manifest_excel', 'extract')
      @columns = load_file(folder, 'columns')
      @defaults = SampleManifestExcel::ConditionalFormattingDefaultList.new(load_file(folder, 'conditional_formattings'))
    end

    should 'insert the name of the column' do
      arguments = SampleManifestExcel::Column.build_arguments(columns.values.first, columns.keys.first, defaults)
      assert_equal columns.keys.first, arguments[:name]
    end

    should 'still have the validations' do
      key = columns.find { |_k, v| v[:validation].present? }.first
      assert SampleManifestExcel::Column.build_arguments(columns[key], key, defaults)[:validation].present?
    end

    should 'combine the conditional formattings correctly' do
      arguments = SampleManifestExcel::Column.build_arguments(columns[:gender], 'gender', defaults)
      assert_equal columns[:gender][:conditional_formattings].length, arguments[:conditional_formattings].length
      arguments[:conditional_formattings].each do |k, _conditional_formatting|
        assert_equal defaults.find_by(k).combine(columns[:gender][:conditional_formattings][k]), arguments[:conditional_formattings][k]
      end
    end

    should 'combine the conditional formattings correctly if there is a formula' do
      arguments = SampleManifestExcel::Column.build_arguments(columns[:supplier_sample_name], 'supplier_sample_name', defaults)
      assert_equal defaults.find_by(:len).combine(columns[:supplier_sample_name][:conditional_formattings][:len])[:formula], arguments[:conditional_formattings][:len][:formula]
    end
  end
end
