# frozen_string_literal: true

require 'rails_helper'

describe Admin::AccessioningToolsController, :accessioning_enabled do
  let(:admin) { create(:admin) }

  let(:study_last_month) { create(:open_study, accession_number: 'ENA123') }
  let(:study_last_week) { create(:open_study, accession_number: 'ENA123') }
  let(:study_today) { create(:open_study, accession_number: 'ENA123') }

  let(:samples_last_month) { create_list(:sample, 5, studies: [study_last_month]) }
  let(:samples_last_week) { create_list(:sample, 5, studies: [study_last_week]) }
  let(:samples_today) { create_list(:sample, 5, studies: [study_today]) }

  before do
    # Override the updated_at timestamps for the tests
    # rubocop:disable Rails/SkipsModelValidations
    samples_last_month.each { |s| s.update_column(:updated_at, 1.month.ago) }
    samples_last_week.each { |s| s.update_column(:updated_at, 1.week.ago) }
    samples_today.each { |s| s.update_column(:updated_at, Time.current) }
    # rubocop:enable Rails/SkipsModelValidations

    session[:user] = admin
  end

  describe '#bulk_accession_preview' do
    before do
      get :bulk_accession_preview, params:
    end

    context 'with bad date parameters' do
      let(:params) { { end_date: 'apples' } }

      it 'returns a bad request status' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns a json content type' do
        expect(response.content_type).to include('application/json')
      end

      it 'returns an error message in the response body' do
        expect(response.parsed_body).to eq(
          'error' => 'Invalid dates provided. Please provide valid start_date and end_date in YYYY-MM-DD format.'
        )
      end
    end

    context 'with invalid date parameters' do
      let(:params) { { start_date: '2026-02-31', end_date: '2026-12-32' } }

      it 'returns a bad request status' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns a json content type' do
        expect(response.content_type).to include('application/json')
      end

      it 'returns an error message in the response body' do
        expect(response.parsed_body).to eq(
          'error' => 'Invalid dates provided. Please provide valid start_date and end_date in YYYY-MM-DD format.'
        )
      end
    end

    context 'with valid date parameters' do
      context 'when the provided date is from today to today' do
        # {start_date: "2026-05-14", end_date: "2026-05-14"}
        let(:today) { Date.current }
        let(:params) { { start_date: today.to_s, end_date: today.to_s } }

        it 'returns a successful response' do
          expect(response).to have_http_status(:ok)
        end

        it 'returns a json content type' do
          expect(response.content_type).to include('application/json')
        end

        it "returns counts of today's samples and studies" do
          expect(response.parsed_body).to include(
            'start_datetime' => today.beginning_of_day.iso8601, # "2026-05-14T00:00:00+01:00"
            'end_datetime' => today.end_of_day.iso8601, # "2026-05-14T23:59:59+01:00"
            'samples_count' => 5,
            'studies_count' => 1
          )
        end
      end

      context 'when the provided date is from last week to today' do
        let(:start_date) { 1.week.ago.to_date }
        let(:today) { Date.current }
        let(:params) { { start_date: start_date.to_s, end_date: today.to_s } }

        it 'returns a successful response' do
          expect(response).to have_http_status(:ok)
        end

        it 'returns a json content type' do
          expect(response.content_type).to include('application/json')
        end

        it "returns counts of last week's and today's samples and studies" do
          body = response.parsed_body
          expect(body).to include(
            'start_datetime' => start_date.beginning_of_day.iso8601, # "2026-05-07T00:00:00+01:00"
            'end_datetime' => today.end_of_day.iso8601, # "2026-05-14T23:59:59+01:00"
            'samples_count' => 10,
            'studies_count' => 2
          )
        end
      end
    end

    describe '#bulk_accession' do
      before do
        allow(SampleAccessioningJob).to receive(:new).and_call_original
        allow(Rails.logger).to receive(:info)

        get :bulk_accession, params:
      end

      context 'with bad date parameters' do
        let(:params) { { end_date: 'apples' } }

        it 'sets a failure flash message' do
          expect(flash[:failure]).to eq('An error occurred, please check that date inputs are correct.')
        end

        it 'redirects to the accessioning tools page' do
          expect(response).to redirect_to(admin_accessioning_tools_path)
        end
      end

      context 'with invalid date parameters' do
        let(:params) { { start_date: '2026-02-31', end_date: '2026-12-32' } }

        it 'sets a failure flash message' do
          expect(flash[:failure]).to eq('An error occurred, please check that date inputs are correct.')
        end

        it 'redirects to the accessioning tools page' do
          expect(response).to redirect_to(admin_accessioning_tools_path)
        end
      end

      context 'with valid date parameters' do
        let(:start_date) { 1.week.ago.to_date }
        let(:end_date) { Date.current }
        let(:params) { { start_date: start_date.to_s, end_date: end_date.to_s } }

        it 'logs the accessioning action' do
          expect(Rails.logger).to have_received(:info).with(
            "Bulk accessioning 10 samples updated between #{start_date.beginning_of_day} and #{end_date.end_of_day}"
          )
        end

        it 'creates a SampleAccessioningJob for each sample within the date range' do
          expect(SampleAccessioningJob).to have_received(:new).exactly(10).times
        end

        it 'sets a success flash message' do
          expect(flash[:success]).to eq('Bulk accessioning complete: 10 samples have been sent for accessioning.')
        end

        it 'redirects to the accessioning tools page' do
          expect(response).to redirect_to(admin_accessioning_tools_path)
        end
      end
    end
  end
end
