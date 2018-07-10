# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::ConditionalFormattingDefaultList, type: :model, sample_manifest_excel: true do
  include SampleManifestExcel::Helpers

  let(:folder) { File.join('spec', 'data', 'sample_manifest_excel', 'extract') }
  let(:rules) { load_file(folder, 'conditional_formattings') }
  let(:defaults) { SampleManifestExcel::ConditionalFormattingDefaultList.new(rules) }

  it 'should have the correct number of defaults' do
    expect(defaults.count).to eq(rules.length)
  end

  it '#find_by should return the correct default' do
    expect(defaults.find_by(:type, rules.keys.first)).to be_present
    expect(defaults.find_by(:type, rules.keys.first.to_sym)).to be_present
  end

  it 'each default should have the correct type' do
    rules.each do |k, _v|
      expect(defaults.find_by(:type, k).type).to eq(k.to_sym)
    end
  end

  it 'should be comparable' do
    expect(SampleManifestExcel::ConditionalFormattingDefaultList.new(rules)).to eq(defaults)
    rules.shift
    expect(SampleManifestExcel::ConditionalFormattingDefaultList.new(rules)).to_not eq(defaults)
  end
end
