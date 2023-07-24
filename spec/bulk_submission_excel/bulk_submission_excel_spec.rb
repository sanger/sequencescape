# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkSubmissionExcel, type: :model, bulk_submission_excel: true do
  before do
    described_class.configure do |config|
      config.folder = File.join('spec', 'data', 'bulk_submission_excel')
      config.load!
    end
  end

  after { described_class.reset! }

  it 'loads the configuration' do
    expect(described_class.configuration).to be_loaded
  end

  it 'loads the correct configuration' do
    configuration = BulkSubmissionExcel::Configuration.new
    configuration.folder = File.join('spec', 'data', 'bulk_submission_excel')
    configuration.load!
    expect(described_class.configuration).to eq(configuration)
  end

  it '#reset should unload the configuration' do
    described_class.reset!
    expect(described_class.configuration).not_to be_loaded
  end
end
