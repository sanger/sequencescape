# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentSecurityPolicyReportsController do
  describe 'POST #create' do
    context 'when a CSP violation report is sent' do
      let(:report) do
        { 'csp-report':
         {
           'document-uri': 'http://localhost:3000/test-url',
           referrer: 'http://localhost:3000/referrer-url',
           'violated-directive': 'script-src-elem',
           'effective-directive': 'script-src-elem',
           'original-policy': "default-src 'self' https:; object-src 'none'; report-uri /csp-reports",
           disposition: 'report',
           'blocked-uri': 'data',
           'status-code': 200,
           'script-sample': ''
         } }
      end

      it 'logs the report' do
        allow(Rails.logger).to receive(:warn)

        post :create, body: report.to_json, as: :json

        expect(Rails.logger).to have_received(:warn).with("[csp-report] #{report.to_json}")
      end

      it 'responds with a 204 No Content status' do
        post :create, body: report.to_json, as: :json

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
