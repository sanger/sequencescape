# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BulkSubmissionExcel::DownloadsController, type: :controller do
  before do
    session[:user] = create :admin

    BulkSubmissionExcel.configure do |config|
      config.folder = File.join('config', 'bulk_submission_excel')
      config.load!
    end
  end

  context 'when receiving a create request' do
    let(:submission) { create :submission }
    let(:plates) { create_list(:plate, 2) }
    let(:barcodes) { plates.map(&:barcodes).flatten.map(&:barcode) }
    let(:action) do
      post :create,
           params: {
             bulk_submission_excel_download: {
               asset_barcodes: barcodes,
               submission_template_id: submission.id
             }
           }
    end

    it 'generates a new submission Excel file' do
      action
      expect(response).to have_http_status(:ok)
    end
  end
end
