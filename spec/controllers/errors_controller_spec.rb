# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ErrorsController, type: :controller do
  errors = %i[not_found internal_server_error service_unavailable]
  formats = [nil, :html, :json, :png, :unknown]

  shared_examples 'renders error as HTML with status' do |error|
    formats.each do |format|
      context "when the request format is #{format}" do
        before { get error, format: }

        it 'returns HTML response' do
          expect(response.content_type).to include('text/html')
        end

        it "renders the #{error} template" do
          expect(response).to render_template(error)
        end

        it "returns #{error} status" do
          expect(response).to have_http_status(error)
        end
      end
    end
  end

  errors.each do |error|
    describe "GET ##{error}" do
      it_behaves_like 'renders error as HTML with status', error
    end
  end
end
