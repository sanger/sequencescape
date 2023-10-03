# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeExcel::ConditionalFormattingDefaultList, :sample_manifest, :sample_manifest_excel,
               type: :model do
  include SequencescapeExcel::Helpers

  let(:folder) { File.join('spec', 'data', 'sample_manifest_excel', 'extract') }
  let(:rules) { load_file(folder, 'conditional_formattings') }
  let(:defaults) { described_class.new(rules) }

  it 'has the correct number of defaults' do
    expect(defaults.count).to eq(rules.length)
  end

  it '#find_by should return the correct default' do
    expect(defaults.find_by(:type, rules.keys.first)).to be_present
    expect(defaults.find_by(:type, rules.keys.first.to_sym)).to be_present
  end

  it 'each default should have the correct type' do
    rules.each { |k, _v| expect(defaults.find_by(:type, k).type).to eq(k.to_sym) }
  end

  it 'is comparable' do
    expect(described_class.new(rules)).to eq(defaults)
    rules.shift
    expect(described_class.new(rules)).not_to eq(defaults)
  end
end
