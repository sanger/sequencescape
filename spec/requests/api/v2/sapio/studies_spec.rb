# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'Sapio Studies API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/sapio/studies' }

  before do
    # Enable the Sapio studies endpoint feature flag for tests
    Flipper.enable(:y26_170_sapio_studies_endpoint)
  end

  after do
    Flipper.disable(:y26_170_sapio_studies_endpoint)
  end

  describe 'GET /api/v2/sapio/studies' do
    context 'when sapio studies endpoint feature flag is disabled' do
      before { Flipper.disable(:y26_170_sapio_studies_endpoint) }

      it 'returns a 404 Not Found response' do
        api_get base_endpoint
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a strict, JSON:API specification compliant error document', :aggregate_failures do
        api_get base_endpoint

        expect(json).to have_key('errors')
        expect(json).not_to have_key('data')
        expect(json['errors']).to be_an(Array)
        expect(json['errors'].size).to eq(1)
      end

      it 'halts immediately and does not trigger any database queries' do
        # Configure the connection object as a message spy
        allow(Study.connection).to receive(:select_all).and_call_original

        api_get base_endpoint

        expect(Study.connection).not_to have_received(:select_all)
          .with(a_string_including('studies'))
      end
    end

    context 'when search parameter is missing' do
      it 'returns a 400 Bad Request status code' do
        api_get base_endpoint
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns a strict, JSON:API compliant document structure', :aggregate_failures do
        api_get base_endpoint

        expect(json).to have_key('errors')
        expect(json).not_to have_key('data')
        expect(json['errors']).to be_an(Array)
        expect(json['errors'].size).to eq(1)
      end

      it 'serializes the exact error keys, tracking parameter origins', :aggregate_failures do
        api_get base_endpoint
        error = json['errors'].first

        expect(error).to include(
          'status' => '400',
          'code' => 'MISSING_SEARCH_PARAMETER',
          'title' => 'Missing Search Parameter',
          'detail' => 'Listing all resources is disabled. You must provide a "name" search parameter.'
        )
        expect(error.dig('source', 'parameter')).to eq('filter[name]')
      end

      it 'halts early and does not execute any database read queries' do
        # Configure the connection object as a message spy
        allow(Study.connection).to receive(:select_all).and_call_original

        api_get base_endpoint

        expect(Study.connection).not_to have_received(:select_all)
          .with(a_string_including('studies'))
      end
    end

    context 'when query results exceed limits' do
      let(:search_term) { 'FuzzyMatch' }

      before do
        # Create 21 records that match our target search string
        # to trigger the boundary limit (MAX_RESULTS = 20)
        21.times { |n| create(:study, name: "#{search_term} Study #{n}") }
      end

      it 'returns a 422 Unprocessable Content status code' do
        api_get "#{base_endpoint}?filter[name]=#{search_term}"
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns a strict, JSON:API specification compliant error document', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=#{search_term}"

        expect(json).to have_key('errors')
        expect(json).not_to have_key('data')
        expect(json['errors']).to be_an(Array)
        expect(json['errors'].size).to eq(1)
      end

      it 'serializes the exact error keys with correct count numbers', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=#{search_term}"

        expect(json['errors'].first).to include(
          'status' => '422',
          'code' => 'RESULT_SET_TOO_LARGE',
          'title' => 'Result set too large',
          'detail' => 'Your search matched at least 21 studies. ' \
                      'Please refine your query to return 20 or fewer results.'
        )
      end

      it 'optimizes the database query calculation using strict collection limits' do
        # Configure a message spy on the underlying scope
        allow(Study).to receive(:all).and_call_original

        api_get "#{base_endpoint}?filter[name]=#{search_term}"

        # Confirms that even though 21 matching items exist, the calculation
        # stops searching after hitting the (MAX_RESULTS + 1) safety boundary
        #
        # XXX: We aimed querying once. This needs redesigning and doing it only
        # in resource.
        expect(Study).to have_received(:all).twice
      end
    end
  end

  # context 'with exact name match' do
  #   let!(:study) { create(:study, name: 'ExactStudy') }

  #   before { create_list(:study, 3) }

  #   it 'returns the matching study' do
  #     api_get "#{base_endpoint}?filter[name]=ExactStudy"
  #     expect(response).to have_http_status(:success)
  #     expect(json['data'].length).to eq(1)
  #     expect(json['data'][0]['attributes']['name']).to eq('ExactStudy')
  #   end

  #   it 'includes uuid in the response' do
  #     api_get "#{base_endpoint}?filter[name]=ExactStudy"
  #     expect(response).to have_http_status(:success)
  #     expect(json['data'][0]['attributes']['uuid']).to eq(study.uuid)
  #   end

  #   it 'includes state in the response' do
  #     api_get "#{base_endpoint}?filter[name]=ExactStudy"
  #     expect(response).to have_http_status(:success)
  #     expect(json['data'][0]['attributes']['state']).to eq('pending')
  #   end

  #   it 'flattens study_metadata attributes' do
  #     study.study_metadata.update(study_description: 'Test Description')
  #     api_get "#{base_endpoint}?filter[name]=ExactStudy"
  #     expect(response).to have_http_status(:success)
  #     expect(json['data'][0]['attributes']['study_description']).to eq('Test Description')
  #   end
  # end

  # context 'with wildcard patterns' do
  #   let!(:study_one) { create(:study, name: 'MyStudy_Genomics') }
  #   let!(:study_two) { create(:study, name: 'MyStudy_Proteomics') }
  #   let!(:study_three) { create(:study, name: 'OtherStudy') }

  #   it 'returns matching studies with * wildcard' do
  #     api_get "#{base_endpoint}?filter[name]=MyStudy*"
  #     expect(response).to have_http_status(:success)
  #     expect(json['data'].length).to eq(2)
  #     expect(json['data'].map { |d| d['attributes']['name'] }).to contain_exactly(
  #       'MyStudy_Genomics',
  #       'MyStudy_Proteomics'
  #     )
  #   end

  #   it 'returns matching studies with leading wildcard by default' do
  #     api_get "#{base_endpoint}?filter[name]=*Genomics"
  #     expect(response).to have_http_status(:success)
  #     expect(json['data'].length).to eq(1)
  #     expect(json['data'][0]['attributes']['name']).to eq('MyStudy_Genomics')
  #   end
  # end

  # context 'with active and inactive studies' do
  #   let!(:active_study) { create(:study, state: 'active', name: 'ActiveStudy') }
  #   let!(:inactive_study) { create(:study, state: 'inactive', name: 'InactiveStudy') }
  #   let!(:pending_study) { create(:study, state: 'pending', name: 'PendyStudy') }

  #   it 'returns both active and inactive studies matching the query' do
  #     api_get "#{base_endpoint}?filter[name]=*Study"
  #     expect(response).to have_http_status(:success)
  #     expect(json['data'].length).to eq(3)
  #     states = json['data'].map { |d| d['attributes']['state'] }
  #     expect(states).to contain_exactly('active', 'inactive', 'pending')
  #   end
  # end

  # context 'with result set limit' do
  #   before { create_list(:study, 25) }

  #   it 'returns error when result set exceeds 20 studies' do
  #     # Query that matches all 25 studies
  #     api_get "#{base_endpoint}?filter[name]=*"
  #     expect(response).to have_http_status(:unprocessable_entity)
  #     expect(json['errors']).to be_present
  #     expect(json['errors'][0]['title']).to eq('Result set too large')
  #     expect(json['errors'][0]['detail']).to include('25 studies')
  #   end

  #   it 'succeeds when result set is exactly 20 studies' do
  #     # Create exactly 20 studies with a unique prefix
  #     20.times do |index|
  #       create(:study, name: "ExactMatch#{index}")
  #     end
  #     api_get "#{base_endpoint}?filter[name]=ExactMatch*"
  #     expect(response).to have_http_status(:success)
  #     expect(json['data'].length).to eq(20)
  #   end
  # end

  # context 'with sparse fieldsets' do
  #   let!(:study) { create(:study, name: 'FieldsetTest') }

  #   before { study.study_metadata.update(study_description: 'Description') }

  #   it 'returns only requested fields' do
  #     api_get "#{base_endpoint}?filter[name]=FieldsetTest&fields[studies]=name,uuid"
  #     expect(response).to have_http_status(:success)
  #     expect(json['data'][0]['attributes'].keys).to contain_exactly('name', 'uuid')
  #   end

  #   it 'always includes uuid when requested' do
  #     api_get "#{base_endpoint}?filter[name]=FieldsetTest&fields[studies]=study_description"
  #     expect(response).to have_http_status(:success)
  #     attrs = json['data'][0]['attributes']
  #     expect(attrs).to have_key('study_description')
  #   end
  # end

  # context 'with no matches' do
  #   before { create(:study, name: 'ExistingStudy') }

  #   it 'returns empty data array' do
  #     api_get "#{base_endpoint}?filter[name]=NonexistentStudy"
  #     expect(response).to have_http_status(:success)
  #     expect(json['data']).to eq([])
  #   end
  # end

  # context 'with special characters in query' do
  #   let!(:study) { create(:study, name: 'Study_With_Underscores') }

  #   it 'handles underscore in query' do
  #     api_get "#{base_endpoint}?filter[name]=Study_With_Underscores"
  #     expect(response).to have_http_status(:success)
  #     expect(json['data'].length).to eq(1)
  #   end

  #   it 'escapes SQL wildcards properly' do
  #     api_get "#{base_endpoint}?filter[name]=Study?With*"
  #     expect(response).to have_http_status(:success)
  #     # Should not throw an error
  #   end
  # end
end
