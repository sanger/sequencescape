# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BulkSubmissionExcel::DownloadsController do
  before do
    session[:user] = create :admin

    BulkSubmissionExcel.configure do |config|
      config.folder = File.join('config', 'bulk_submission_excel')
      config.load!
    end
  end

  context 'when receiving a create request' do
    let(:submission) { create :submission }
    let(:plates) { create_list(:plate, 6) }
    let(:barcodes) { plates.map(&:barcodes).flatten.map(&:barcode) }
    let(:action) do
      post :create,
           params: {
             bulk_submission_excel_download: {
               asset_barcodes: barcodes.join("\n"),
               submission_template_id: submission.id
             }
           }
    end

    it 'generates a new submission Excel file' do
      action
      expect(response).to have_http_status(:ok)
    end

    it 'generates an Excel file with the correct headers' do
      action
      expect(response.headers['Content-Type']).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      expect(response.headers['Content-Disposition']).to include(
        "#{barcodes.first}_to_#{barcodes.last}_#{Time.current.utc.strftime('%Y%m%d')}_#{session[:user].login}.xlsx"
      )
    end

    context 'when only one barcode is provided' do
      let(:plates) { create_list(:plate, 1) }

      it 'generates an Excel file with the correct headers' do
        action
        expect(response.headers['Content-Disposition']).to include(
          "#{barcodes.first}_to_#{barcodes.first}_#{Time.current.utc.strftime('%Y%m%d')}_#{session[:user].login}.xlsx"
        )
      end
    end
  end
end
