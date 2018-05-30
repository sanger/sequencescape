require 'rails_helper'

RSpec.describe SampleManifestExcel::ConditionalFormattingList, type: :model, sample_manifest_excel: true do
  include SampleManifestExcel::Helpers

  let(:folder) { File.join('spec', 'data', 'sample_manifest_excel', 'extract') }
  let(:rules) { load_file(folder, 'conditional_formattings') }
  let(:conditional_formatting_list) { SampleManifestExcel::ConditionalFormattingList.new(rules) }
  let(:worksheet) { Axlsx::Workbook.new.add_worksheet }
  let(:options) { build(:range).references.merge(worksheet: worksheet) }

  it 'must have the correct number of options' do
    expect(conditional_formatting_list.count).to eq(rules.length)
  end

  it '#options provides a list of conditional formatting options' do
    expect(conditional_formatting_list.options.count).to eq(rules.length)
    expect(rules.values.all? { |rule| conditional_formatting_list.options.include? rule['options'] }).to be_truthy
  end

  it '#update updates all of the conditional formatting rules' do
    conditional_formatting_list.update(options)
    expect(conditional_formatting_list.all? { |conditional_formatting| conditional_formatting.styled? }).to be_truthy
  end

  it '#update should update the worksheet with conditional formatting rules' do
    conditional_formatting_list.update(options)
    expect(worksheet.conditional_formatting_rules.to_a.first.rules.length).to eq(rules.length)
    expect(worksheet.conditional_formatting_rules.to_a.first.sqref).to eq(options[:reference])
    expect(conditional_formatting_list).to be_saved
  end

  it '#update should only work if there are some conditional formattings in the list' do
    conditional_formatting_list = SampleManifestExcel::ConditionalFormattingList.new
    conditional_formatting_list.update(options)
    expect(conditional_formatting_list).to_not be_saved
  end

  # TODO: This is in the wrong place. Probably should be tested in conditional formatting. Getting formula from worksheet is ugly.
  it '#update with formula should correctly assign the formula to the worksheet' do
    conditional_formatting_list = SampleManifestExcel::ConditionalFormattingList.new(rule_1: FactoryBot.attributes_for(:conditional_formatting_with_formula))
    conditional_formatting_list.update(options)
    expect(conditional_formatting_list).to be_saved
    expect(worksheet.conditional_formatting_rules.to_a.first.rules.first.formula.first).to eq(ERB::Util.html_escape(SampleManifestExcel::Formula.new(options.merge(FactoryBot.attributes_for(:conditional_formatting_with_formula)[:formula])).to_s))
  end

  it 'should be comparable' do
    expect(SampleManifestExcel::ConditionalFormattingList.new(rules)).to eq(conditional_formatting_list)
    rules.shift
    expect(SampleManifestExcel::ConditionalFormattingList.new(rules)).to_not eq(conditional_formatting_list)
    expect(SampleManifestExcel::ConditionalFormattingList.new(rules)).to_not eq(Array.new)
  end

  it 'should be duplicated correctly' do
    dup = conditional_formatting_list.dup
    conditional_formatting_list.update(options)
    expect(dup.any? { |conditional_formatting| conditional_formatting.styled? }).to be_falsey
  end
end
