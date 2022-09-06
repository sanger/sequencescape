# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BulkSubmissionExcel::DownloadsController, type: :controller do
  context 'when receiving a create request' do
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

    end
  end
end