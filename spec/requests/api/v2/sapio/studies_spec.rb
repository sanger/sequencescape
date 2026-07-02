# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'Sapio Studies API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/sapio/studies' }

  let(:study_attrs) do
    %w[
      name
      uuid
      created_at
      updated_at
      blocked
      state
      ethically_approved
      enforce_data_release
      enforce_accessioning
    ]
  end

  let(:study_metadata_attrs) do
    %w[
      old_sac_sponsor
      study_description
      contaminated_human_dna
      study_project_id
      study_abstract
      study_study_title
      study_ebi_accession_number
      study_sra_hold
      contains_human_dna
      study_name_abbreviation
      reference_genome_old
      data_release_strategy
      data_release_standard_agreement
      data_release_timing
      data_release_delay_reason
      data_release_delay_other_comment
      data_release_delay_period
      data_release_delay_approval
      data_release_delay_reason_comment
      data_release_prevention_reason
      data_release_prevention_approval
      data_release_prevention_reason_comment
      snp_study_id
      snp_parent_study_id
      bam
      study_type_id
      study_type_name
      data_release_study_type_id
      data_release_study_type_name
      reference_genome_id
      reference_genome_name
      array_express_accession_number
      dac_policy
      ega_policy_accession_number
      ega_dac_accession_number
      commercially_available
      number_of_gigabases_per_sample
      hmdmc_approval_number
      created_at
      updated_at
      remove_x_and_autosomes
      dac_policy_title
      separate_y_chromosome_data
      data_access_group
      prelim_id
      program_id
      program_name
      s3_email_list
      data_deletion_period
      contaminated_human_data_access_group
      data_release_prevention_other_comment
      ebi_library_strategy
      ebi_library_source
      ebi_library_selection
      data_release_timing_publication_comment
      data_share_in_preprint
    ]
  end

  let(:study_type_attrs) do
    %w[
      name
      valid_type
      created_at
      updated_at
      valid_for_creation
    ]
  end

  let(:data_release_study_type_attrs) do
    %w[
      name
      created_at
      updated_at
      for_array_express
      is_default
      is_assay_type
    ]
  end

  let(:reference_genome_attrs) do
    %w[
      name
      uuid
      created_at
      updated_at
    ]
  end

  let(:program_attrs) do
    %w[
      name
      created_at
      updated_at
    ]
  end

  let(:user_attrs) do
    %w[
      uuid
      login
      first_name
      last_name
    ]
  end

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
          'code' => 'MISSING_SEARCH_PARAM',
          'title' => 'Missing Search Parameter',
          'detail' => 'The required search parameter is missing or blank.'
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

      it 'returns a 422 Unprocessable Entity status code' do
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
          'title' => 'Result Set Too Large',
          'detail' => 'Your search matched too many results. ' \
                      'Please refine your query to return fewer results.'
        )
      end

      it 'optimizes the database query calculation using strict collection limits' do
        # Configure a message spy on the underlying scope
        allow(Study).to receive(:all).and_call_original

        api_get "#{base_endpoint}?filter[name]=#{search_term}"

        # Stops processing after hitting the (MAX_RESULTS + 1) safety boundary
        expect(Study).to have_received(:all).once
      end
    end

    context 'when maxResults custom query parameter is supplied' do
      let(:search_term) { 'FuzzyMatch' }

      before do
        25.times { |n| create(:study, name: "#{search_term} Study #{n}") }
      end

      it 'overrides the default maximum result limit', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=#{search_term}&maxResults=25"

        expect(response).to have_http_status(:ok)
        expect(json['data'].size).to eq(25)
      end

      it 'ignores non-positive maxResults values', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=#{search_term}&maxResults=0"

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors'].first['code']).to eq('RESULT_SET_TOO_LARGE')
      end

      it 'ignores negative maxResults values', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=#{search_term}&maxResults=-5"

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors'].first['code']).to eq('RESULT_SET_TOO_LARGE')
      end

      it 'ignores non-integer maxResults values', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=#{search_term}&maxResults=abc"

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors'].first['code']).to eq('RESULT_SET_TOO_LARGE')
      end

      it 'ignores maxResults values exceeding the upper limit', :aggregate_failures do
        # See Api::V2::Sapio::StudiesController::RESULTS_RANGE -> 1..1000
        api_get "#{base_endpoint}?filter[name]=#{search_term}&maxResults=2000"

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors'].first['code']).to eq('RESULT_SET_TOO_LARGE')
      end
    end

    context 'when study name contains UTF-8 characters' do
      before { create(:study, name: 'Müller Café Study') }

      let(:query) { Rack::Utils.build_nested_query(filter: { name: 'Café' }) }

      it 'returns the matching study', :aggregate_failures do
        api_get "#{base_endpoint}?#{query}"

        expect(response).to have_http_status(:success)
        expect(json['data'].length).to eq(1)
        expect(json['data'][0]['attributes']['name']).to eq('Müller Café Study')
      end
    end

    context 'when there are multiple matches' do
      before do
        create(:study, name: 'Study One')
        create(:study, name: 'Study Two')
        create(:study, name: 'Study Three')
        create(:study, name: 'Non-matching Study') # by wildcard matching
      end

      it 'returns all matching studies', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=Study*"
        expect(response).to have_http_status(:success)
        expect(json['data'].length).to eq(3)
        names = json['data'].map { |d| d['attributes']['name'] }
        expect(names).to contain_exactly('Study One', 'Study Two', 'Study Three')
      end

      it 'does not return non-matching studies', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=Study*"
        expect(response).to have_http_status(:success)
        names = json['data'].map { |d| d['attributes']['name'] }
        expect(names).not_to include('Non-matching Study')
      end
    end

    context 'without sparse fields' do
      before do
        create(:study, name: 'Study A')
      end

      it 'returns all attributes for study', :aggregate_failures do
        # NOTE: Any `*` or `?` outside quoted tokens activates wildcard search.
        #       `Study*` means "Study" followed by any characters.
        api_get "#{base_endpoint}?filter[name]=Study*"
        expect(response).to have_http_status(:success)
        json['data'].each do |study|
          expect(study['attributes']).to include(*study_attrs)
        end
      end

      it 'returns all attributes for included study_metadata', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=Study*&include=study_metadata"
        expect(response).to have_http_status(:success)
        json['included'].select { |item| item['type'] == 'study_metadata' }.each do |study_metadata|
          expect(study_metadata['attributes']).to include(*study_metadata_attrs)
        end
      end

      it 'returns all attributes for included study_metadata.study_type', :aggregate_failures do
        # NOTE: The include dot notation includes all intermediate study_metadata segments as well.
        # NOTE: The study_type include is singular because it is a has_one relationship.
        api_get "#{base_endpoint}?filter[name]=Study*&include=study_metadata.study_type"
        expect(response).to have_http_status(:success)
        # NOTE: type is pluralized in the JSON:API response.
        json['included'].select { |item| item['type'] == 'study_types' }.each do |study_type|
          expect(study_type['attributes']).to include(*study_type_attrs)
        end
      end

      # rubocop:disable RSpec/ExampleLength
      it 'returns all attributes for included study_metadata.data_release_study_type', :aggregate_failures do
        # NOTE: More includes can be added, separated by commas.
        api_get "#{base_endpoint}?filter[name]=Study*" \
                '&include=study_metadata.data_release_study_type,study_metadata.study_type'
        expect(response).to have_http_status(:success)
        json['included'].select { |item| item['type'] == 'data_release_study_types' }.each do |data_release_study_type|
          expect(data_release_study_type['attributes']).to include(*data_release_study_type_attrs)
        end
      end
      # rubocop:enable RSpec/ExampleLength

      it 'returns all attributes for included study_metadata.reference_genome', :aggregate_failures do
        # NOTE: reference_genome_name attribute is available on study_metadata as well, for convenience.
        api_get "#{base_endpoint}?filter[name]=Study*&include=study_metadata.reference_genome"
        expect(response).to have_http_status(:success)
        json['included'].select { |item| item['type'] == 'reference_genomes' }.each do |reference_genome|
          expect(reference_genome['attributes']).to include(*reference_genome_attrs)
        end
      end

      it 'returns all attributes for included study_metadata.program', :aggregate_failures do
        # NOTE: program_name attribute is available on study_metadata as well, for convenience.
        api_get "#{base_endpoint}?filter[name]=Study*&include=study_metadata.program"
        expect(response).to have_http_status(:success)
        json['included'].select { |item| item['type'] == 'programs' }.each do |program|
          expect(program['attributes']).to include(*program_attrs)
        end
      end

      it 'returns all attributes for included user', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=Study*&include=user"
        expect(response).to have_http_status(:success)
        json['included'].select { |item| item['type'] == 'users' }.each do |user|
          expect(user['attributes']).to include(*user_attrs)
        end
      end
    end

    # rubocop:disable RSpec/ExampleLength
    context 'with sparse fields' do
      before do
        create(:study, name: 'Study A')
      end

      it 'returns only the requested fields for study', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=Study*&fields[studies]=name,uuid"
        expect(response).to have_http_status(:success)
        json['data'].each do |study|
          expect(study['attributes'].keys).to contain_exactly('name', 'uuid')
        end
      end

      it 'returns only the requested fields for included study_metadata', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=Study*&include=study_metadata" \
                '&fields[study_metadata]=study_description,study_abstract'
        expect(response).to have_http_status(:success)
        json['included'].select { |item| item['type'] == 'study_metadata' }.each do |study_metadata|
          expect(study_metadata['attributes'].keys).to contain_exactly('study_description', 'study_abstract')
        end
      end

      it 'returns only the requested fields for included study_metadata.study_type', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=Study*&include=study_metadata.study_type" \
                '&fields[study_types]=name,valid_type'
        expect(response).to have_http_status(:success)
        json['included'].select { |item| item['type'] == 'study_types' }.each do |study_type|
          expect(study_type['attributes'].keys).to contain_exactly('name', 'valid_type')
        end
      end

      it 'returns only the requested fields for included study_metadata.data_release_study_type', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=Study*&include=study_metadata.data_release_study_type" \
                '&fields[data_release_study_types]=name,for_array_express'
        expect(response).to have_http_status(:success)
        json['included'].select { |item| item['type'] == 'data_release_study_types' }.each do |data_release_study_type|
          expect(data_release_study_type['attributes'].keys).to contain_exactly('name', 'for_array_express')
        end
      end

      it 'returns only the requested fields for included study_metadata.reference_genome', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=Study*&include=study_metadata.reference_genome" \
                '&fields[reference_genomes]=name,uuid'
        expect(response).to have_http_status(:success)
        json['included'].select { |item| item['type'] == 'reference_genomes' }.each do |reference_genome|
          expect(reference_genome['attributes'].keys).to contain_exactly('name', 'uuid')
        end
      end

      it 'returns only the requested fields for included study_metadata.program', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=Study*&include=study_metadata.program" \
                '&fields[programs]=name,created_at'
        expect(response).to have_http_status(:success)
        json['included'].select { |item| item['type'] == 'programs' }.each do |program|
          expect(program['attributes'].keys).to contain_exactly('name', 'created_at')
        end
      end

      it 'returns only the requested fields for included user', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=Study*&include=user" \
                '&fields[users]=first_name,last_name'
        expect(response).to have_http_status(:success)
        json['included'].select { |item| item['type'] == 'users' }.each do |user|
          expect(user['attributes'].keys).to contain_exactly('first_name', 'last_name')
        end
      end
    end
    # rubocop:enable RSpec/ExampleLength

    context 'with active and inactive studies' do
      before do
        create(:study, state: 'active', name: 'ActiveStudy')
        create(:study, state: 'inactive', name: 'InactiveStudy')
      end

      it 'returns both active and inactive studies matching the query', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=*Study"
        expect(response).to have_http_status(:success)
        expect(json['data'].length).to eq(2)
        states = json['data'].map { |d| d['attributes']['state'] }
        expect(states).to include('active', 'inactive')
      end
    end

    context 'with no matches' do
      before { create(:study, name: 'ExistingStudy') }

      it 'returns empty data array', :aggregate_failures do
        api_get "#{base_endpoint}?filter[name]=NonexistentStudy"
        expect(response).to have_http_status(:success)
        expect(json['data']).to eq([])
      end
    end
  end

  describe 'GET /api/v2/sapio/studies/:id' do
    before do
      Flipper.enable(:y26_170_sapio_studies_endpoint)
    end

    after do
      Flipper.disable(:y26_170_sapio_studies_endpoint)
    end

    context 'when sapio studies endpoint feature flag is disabled' do
      before { Flipper.disable(:y26_170_sapio_studies_endpoint) }

      it 'returns a 404 Not Found response' do
        api_get base_endpoint
        expect(response).to have_http_status(:not_found)
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
