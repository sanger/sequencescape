require 'rails_helper'

RSpec.describe SampleManifestExcel::ColumnList, type: :model, sample_manifest_excel: true do
  include SampleManifestExcel::Helpers

  let(:folder)                  { File.join('spec', 'data', 'sample_manifest_excel', 'extract') }
  let(:yaml)                    { load_file(folder, 'columns') }
  let(:conditional_formattings) { SampleManifestExcel::ConditionalFormattingDefaultList.new(load_file(folder, 'conditional_formattings')) }
  let(:column_list)             { SampleManifestExcel::ColumnList.new(yaml, conditional_formattings) }
  let(:ranges)                  { build(:range_list, options: load_file(folder, 'ranges')) }

  it 'creates a list of columns' do
    expect(column_list.count).to eq(yaml.length)
  end

  it 'creates a list of columns when passed a bunch of columns' do
    columns = build_list(:column, 5)
    column_list = SampleManifestExcel::ColumnList.new(build_list(:column, 5))
    expect(column_list.count).to eq(columns.length)
    expect(column_list.all? { |column| column_list.find_by(:name, column.name).present? }).to be_truthy
  end

  it 'has some conditional formattings' do
    expect(column_list.find_by(:name, :gender).conditional_formattings.count).to eq(yaml[:gender][:conditional_formattings].length)
    expect(column_list.find_by(:name, :sibling).conditional_formattings.count).to eq(yaml[:sibling][:conditional_formattings].length)
  end

  it '#headings returns list of headings' do
    expect(column_list.headings).to eq(yaml.values.collect { |column| column[:heading] })
  end

  it '#column_values returns all of the values for the column list' do
    sanger_sample_id_column = build(:sanger_sample_id_column)
    column_list.add(sanger_sample_id_column)
    expect(column_list.column_values.length).to eq(column_list.count)
    expect(column_list.column_values.last).to eq(sanger_sample_id_column.value)
  end

  it '#column_values with inserts returns all of the values for the column list along with the inserts' do
    names = column_list.names
    replacements = { names.first => 'first', names.last => 'last' }
    values = column_list.column_values(replacements)
    expect(values.first).to eq('first')
    expect(values.last).to eq('last')
  end

  it 'each column has a number' do
    column_list.each_with_index do |column, i|
      expect(column_list.find_by(:number, i + 1)).to eq(column)
    end
  end

  it '#extract returns correct list of columns' do
    names = column_list.names[0..5]
    list = column_list.extract(names)
    expect(column_list.count).to eq(yaml.length)
    expect(list.count).to eq(names.length)
    names.each_with_index do |name, i|
      expect(list.find_by(:name, name).number).to eq(i + 1)
    end
  end

  it '#extract doesnt affect original list of columns' do
    column_number = column_list.values[4].number
    names = column_list.names[0..2] + column_list.names[4..5]
    list = column_list.extract(names)
    expect(column_list.values[4].number).to eq(column_number)
  end

  it '#extract can extract columns by any key' do
    new_list = column_list.extract(column_list.headings)
    expect(new_list.count).to eq(column_list.count)
  end

  it '#extract with invalid key provides a descriptive error message' do
    bad_column = build(:column)
    new_list = column_list.extract(column_list.headings << bad_column.heading)
    expect(new_list).to_not be_valid
    expect(new_list.errors.full_messages.to_s).to include(bad_column.heading)
  end

  it '#update updates columns' do
    column_list.update(10, 15, ranges, Axlsx::Workbook.new.add_worksheet)
    expect(column_list.all? { |column| column.updated? }).to be_truthy
  end

  it 'duplicates correctly' do
    n = column_list.count
    dupped = column_list.dup
    expect(column_list.count).to eq(n)
    expect(dupped.count).to eq(n)
    column_list.update(10, 15, ranges, Axlsx::Workbook.new.add_worksheet)
    expect(dupped.any? { |column| column.updated? }).to be_falsey
  end

  it 'must have some columns to be valid' do
    expect(SampleManifestExcel::ColumnList.new(yaml, conditional_formattings)).to be_valid
    expect(SampleManifestExcel::ColumnList.new(nil, conditional_formattings)).to_not be_valid
  end

  it '#find_by_or_null returns a null object if none exists for key and value' do
    expect(column_list.find_by_or_null(:name, :bad_value).number).to eq(-1) # rubocop:disable all
  end

  it '#except will remove the offending column' do
    expect(column_list.except(yaml.keys.first).find_by(:name, yaml.keys.first)).to be_nil
    expect(column_list.first.number).to eq(1)
  end

  it '#with should add an extra column' do
    column_list.with(:my_new_column)
    expect(column_list.find_by(:name, :my_new_column)).to be_present
    expect(column_list.find_by(:heading, 'my_new_column')).to be_present
  end
end
