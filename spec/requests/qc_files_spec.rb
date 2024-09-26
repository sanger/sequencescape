# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'QcFiles' do
  let(:authorised_app) { create(:api_application) }

  describe 'create qc file' do
    let(:filename) { Rails.root.join('spec/data/parsers/cardinal_pbmc_count.csv').expand_path }
    let(:file) { File.open(filename) }
    let(:plate) { create(:plate_with_empty_wells, well_count: 96) }

    it 'successful' do
      headers = {
        'HTTP_ACCEPT' => 'application/json',
        'CONTENT_TYPE' => 'sequencescape/qc_file',
        'HTTP_CONTENT_DISPOSITION' => 'form-data; filename="cardinal_pbmc_count.csv"',
        'HTTP_X_SEQUENCESCAPE_CLIENT_ID' => authorised_app.key,
        'HTTP_COOKIE' => ''
      }

      post("/api/1/#{plate.uuid}/qc_files", params: file.read, headers:)

      expect(response).to have_http_status(:success)

      expect(QcResult.count).to eq(16)
    end
  end
end
