# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel, type: :model, sample_manifest_excel: true, sample_manifest: true do
  before do
    described_class.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  after { described_class.reset! }

  it 'loads the configuration' do
    expect(described_class.configuration).to be_loaded
  end

  it 'loads the correct configuration' do
    configuration = SampleManifestExcel::Configuration.new
    configuration.folder = File.join('spec', 'data', 'sample_manifest_excel')
    configuration.load!
    expect(described_class.configuration).to eq(configuration)
  end

  it '#reset should unload the configuration' do
    described_class.reset!
    expect(described_class.configuration).not_to be_loaded
  end

  it 'has a first row' do
    expect(SampleManifestExcel::FIRST_ROW).to be_present
    expect(SampleManifestExcel::FIRST_ROW).to eq(9)
  end
end
