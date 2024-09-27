# frozen_string_literal: true
require 'rails_helper'
RSpec.describe BulkSubmissionExcel::DownloadsController, type: :controller do
  subject(:downloads_controller) { described_class.new }

  let(:submission) { create(:submission) }

  before do
    session[:user] = create :admin

    BulkSubmissionExcel.configure do |config|
      config.folder = File.join('config', 'bulk_submission_excel')
      config.load!
    end
  end

  describe 'GET #new' do
    it 'renders the new template' do
      get :new, params: { submission_template_id: submission.id }
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    let(:plates) { create_list(:plate, 6) }
    let(:barcodes) { plates.map(&:barcodes).flatten.map(&:barcode) }
    let(:valid_attributes) do
      { bulk_submission_excel_download: { asset_barcodes: barcodes.join("\n"), submission_template_id: submission.id } }
    end
    let(:invalid_attributes) do
      { bulk_submission_excel_download: { asset_barcodes: 'invalid barcode', submission_template_id: submission.id } }
    end

    context 'with valid params' do
      it 'creates a new download and sends a file' do
        post :create, params: valid_attributes
        expect(response.header['Content-Type']).to include downloads_controller.class::CONTENT_TYPE
      end

      it 'generates a new submission Excel file' do
        post :create, params: valid_attributes
        expect(response).to have_http_status(:ok)
      end

      it 'generates an Excel file with the correct headers' do
        post :create, params: valid_attributes
        expect(response.headers['Content-Type']).to eq(downloads_controller.class::CONTENT_TYPE)
        expect(response.headers['Content-Disposition']).to include(
          "#{barcodes.first}_to_#{barcodes.last}_#{Time.current.utc.strftime('%Y%m%d')}_#{session[:user].login}.xlsx"
        )
      end

      context 'when only one barcode is provided' do
        let(:plates) { create_list(:plate, 1) }

        it 'generates an Excel file with the correct headers' do
          post :create, params: valid_attributes
          expect(response.headers['Content-Disposition']).to include(
            "#{barcodes.first}_#{Time.current.utc.strftime('%Y%m%d')}_#{session[:user].login}.xlsx"
          )
        end
      end

      context 'when no barcodes are provided' do
        let(:barcodes) { [] }

        it 'redirects back with an error message' do
          post :create, params: valid_attributes
          expect(response.headers['Content-Disposition']).to include(
            "_to__#{Time.current.utc.strftime('%Y%m%d')}_#{session[:user].login}.xlsx"
          )
          expect(flash[:error]).not_to be_present
        end
      end
    end

    context 'with invalid params' do
      it 'redirects back with an error message' do
        post :create, params: invalid_attributes
        expect(response).to redirect_to(bulk_submissions_path)
        expect(flash[:error]).to be_present
      end
    end
  end
end
