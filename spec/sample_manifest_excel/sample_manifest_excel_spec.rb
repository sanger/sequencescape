# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel, type: :model, sample_manifest_excel: true do
  before do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  after { SampleManifestExcel.reset! }

  it 'loads the configuration' do
    expect(SampleManifestExcel.configuration).to be_loaded
  end

  it 'loads the correct configuration' do
    configuration = SampleManifestExcel::Configuration.new
    configuration.folder = File.join('spec', 'data', 'sample_manifest_excel')
    configuration.load!
    expect(SampleManifestExcel.configuration).to eq(configuration)
  end

  it '#reset should unload the configuration' do
    SampleManifestExcel.reset!
    expect(SampleManifestExcel.configuration).not_to be_loaded
  end

  it 'has a first row' do
    expect(SampleManifestExcel::FIRST_ROW).to be_present
    expect(SampleManifestExcel::FIRST_ROW).to eq(9)
  end
end
