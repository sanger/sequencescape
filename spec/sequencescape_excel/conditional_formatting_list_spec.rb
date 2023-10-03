# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeExcel::ConditionalFormattingList, :sample_manifest, :sample_manifest_excel,
               type: :model do
  include SequencescapeExcel::Helpers

  let(:folder) { File.join('spec', 'data', 'sample_manifest_excel', 'extract') }
  let(:rules) { load_file(folder, 'conditional_formattings') }
  let(:conditional_formatting_list) { described_class.new(rules) }
  let(:worksheet) { Axlsx::Workbook.new.add_worksheet }
  let(:options) { build(:range).references.merge(worksheet: worksheet) }

  it 'must have the correct number of options' do
    expect(conditional_formatting_list.count).to eq(rules.length)
  end

  it '#options provides a list of conditional formatting options' do
    expect(conditional_formatting_list.options.count).to eq(rules.length)
    expect(rules.values).to be_all { |rule| conditional_formatting_list.options.include? rule['options'] }
  end

  it '#update updates all of the conditional formatting rules' do
    conditional_formatting_list.update(options)
    expect(conditional_formatting_list).to be_all(&:styled?)
  end

  it '#update should update the worksheet with conditional formatting rules' do
    conditional_formatting_list.update(options)
    expect(worksheet.conditional_formatting_rules.to_a.first.rules.length).to eq(rules.length)
    expect(worksheet.conditional_formatting_rules.to_a.first.sqref).to eq(options[:reference])
    expect(conditional_formatting_list).to be_saved
  end

  it '#update should only work if there are some conditional formattings in the list' do
    conditional_formatting_list = described_class.new
    conditional_formatting_list.update(options)
    expect(conditional_formatting_list).not_to be_saved
  end

  # TODO: This is in the wrong place. Probably should be tested in conditional formatting. Getting formula from
  # worksheet is ugly.
  it '#update with formula should correctly assign the formula to the worksheet' do
    conditional_formatting_list = described_class.new(rule_1: attributes_for(:conditional_formatting_with_formula))
    conditional_formatting_list.update(options)
    expect(conditional_formatting_list).to be_saved
    expect(worksheet.conditional_formatting_rules.to_a.first.rules.first.formula.first).to eq(
      ERB::Util.html_escape(
        SequencescapeExcel::Formula.new(options.merge(attributes_for(:conditional_formatting_with_formula)[:formula]))
          .to_s
      )
    )
  end

  it 'is comparable' do
    expect(described_class.new(rules)).to eq(conditional_formatting_list)
    rules.shift
    expect(described_class.new(rules)).not_to eq(conditional_formatting_list)
    expect(described_class.new(rules)).not_to eq([])
  end

  it 'is duplicated correctly' do
    dup = conditional_formatting_list.dup
    conditional_formatting_list.update(options)
    expect(dup).not_to be_any(&:styled?)
  end
end
