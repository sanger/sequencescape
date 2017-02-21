require 'test_helper'

class SpecialisedFieldTest < ActiveSupport::TestCase
  attr_reader :column_list, :row, :column

  class MySecretField
    include SampleManifestExcel::SpecialisedField
  end

  def setup
    @column_list = build(:column_list)
    @column = build(:column, name: :my_secret_field, heading: 'My Secret Field', value: 'My Secret Value')
    column_list.add_with_number(column)
    @row = build(:row, data: column_list.column_values, columns: column_list)
  end

  test 'should have a type' do
    assert_equal :my_secret_field, MySecretField.new.type
  end

  test 'should update value from row' do
    field = MySecretField.new.update(row: row)
    assert field.value_present?
    assert_equal 'My Secret Value', field.value
  end
end
