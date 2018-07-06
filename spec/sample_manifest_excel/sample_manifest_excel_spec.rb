# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel, type: :model, sample_manifest_excel: true do
  before(:each) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

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
    expect(SampleManifestExcel.configuration).to_not be_loaded
  end

  it 'should have a first row' do
    expect(SampleManifestExcel::FIRST_ROW).to be_present
    expect(SampleManifestExcel::FIRST_ROW).to eq(9)
  end

  after(:each) do
    SampleManifestExcel.reset!
  end
end
