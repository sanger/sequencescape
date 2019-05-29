# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkSubmissionExcel, type: :model, bulk_submission_excel: true do
  before do
    BulkSubmissionExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'bulk_submission_excel')
      config.load!
    end
  end

  after do
    BulkSubmissionExcel.reset!
  end

  it 'loads the configuration' do
    expect(BulkSubmissionExcel.configuration).to be_loaded
  end

  it 'loads the correct configuration' do
    configuration = BulkSubmissionExcel::Configuration.new
    configuration.folder = File.join('spec', 'data', 'bulk_submission_excel')
    configuration.load!
    expect(BulkSubmissionExcel.configuration).to eq(configuration)
  end

  it '#reset should unload the configuration' do
    BulkSubmissionExcel.reset!
    expect(BulkSubmissionExcel.configuration).not_to be_loaded
  end
end
