# frozen_string_literal: true

require 'rails_helper'

describe 'Sapio Operations API' do
  let(:base_endpoint) { '/api/v2/sapio/operations' }
  let(:integration_hub_app) do
    create(:api_application, name: ApiApplication::INTEGRATION_HUB_NAME)
  end
  let(:other_app) { create(:api_application) }
  # The smallest payload that is valid against the configured schema: one
  # tube with one sample, and a work order for the tube.
  let(:valid_payload) do
    {
      request: { external_id: 'request-1',
                 request_type: 'reception_and_work_order',
                 schema_version: '1' },
      labware: [{ uuid: '6f1c1d2e-0000-4000-8000-000000000001',
                  barcode: 'TUBE-1', type: 'tube',
                  receptacles: [receptacle] }],
      work_order: { external_id: 'work-order-1', service_name: 'service',
                    requested_by: 'user', cost_code: 'S0001',
                    requested_labware_identifiers: ['TUBE-1'], options: {} }
    }
  end
  let(:receptacle) do
    { position: nil, uuid: '6f1c1d2e-0000-4000-8000-000000000002',
      samples: [{ uuid: '6f1c1d2e-0000-4000-8000-000000000003',
                  study_uuid: '6f1c1d2e-0000-4000-8000-000000000004',
                  sanger_sample_id: 'SAMPLE-1',
                  supplier_sample_name: 'sample 1' }] }
  end
  let(:body) { valid_payload.to_json }
  let(:json) { response.parsed_body }
  let(:schema_validator) do
    settings = Rails.application.config
    Schemas::Provider.configured.validator_for(
      subject: settings.sapio_schema_subject,
      version: Schemas::Provider.parse_version(settings.sapio_schema_version)
    )
  end

  def post_request(api_key: nil, request_body: body)
    headers = { 'CONTENT_TYPE' => 'application/json' }
    headers['X-Sequencescape-Client-Id'] = api_key if api_key
    post base_endpoint, params: request_body, headers: headers
  end

  it 'uses a payload that is valid against the configured schema' do
    expect(schema_validator.validate(JSON.parse(body))).to eq([])
  end

  context 'when the feature flag is disabled',
          :sapio_operations_endpoint_disabled do
    before { post_request(api_key: integration_hub_app.key) }

    it 'returns not found' do
      expect(response).to have_http_status(:not_found)
    end

    it 'returns a feature disabled error' do
      expect(json.dig('errors', 0, 'code')).to eq('FEATURE_DISABLED')
    end
  end

  context 'when the feature flag is enabled',
          :sapio_operations_endpoint_enabled do
    context 'without an API key when API keys are mandatory' do
      before do
        Flipper.enable(:y25_442_make_api_key_mandatory)
        post_request
      end

      it 'returns unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'without an API key when API keys are optional' do
      before do
        Flipper.disable(:y25_442_make_api_key_mandatory)
        post_request
      end

      it 'returns forbidden' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with an unknown API key' do
      before { post_request(api_key: 'unknown') }

      it 'returns unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with another application API key' do
      before { post_request(api_key: other_app.key) }

      it 'returns forbidden' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns an Integration Hub API key required error' do
        expect(json.dig('errors', 0, 'detail'))
          .to eq('Integration Hub API key required.')
      end
    end

    context 'when Rails logs the request parameters' do
      # The parameters Rails logs, taken from its start_processing event, so
      # the check doesn't depend on which logger or log level is in use.
      let(:logged_params) { {} }

      before do
        capture = ->(*, payload) { logged_params.merge!(payload[:params]) }
        ActiveSupport::Notifications.subscribed(
          capture, 'start_processing.action_controller'
        ) { post_request(api_key: integration_hub_app.key) }
      end

      it 'logs each part of the payload as filtered' do
        expect(logged_params.slice('request', 'labware', 'work_order'))
          .to eq('request' => '[FILTERED]', 'labware' => '[FILTERED]',
                 'work_order' => '[FILTERED]')
      end

      it 'does not log the payload values' do
        expect(logged_params.to_s).not_to include('request-1')
      end

      it 'does not log a wrapped copy of the payload' do
        expect(logged_params).not_to have_key('operation')
      end
    end

    # Only a new request is checked against the schema, so an earlier
    # operation is found first, whatever the schema says about its payload.
    context 'when a stored request is repeated that the schema rejects' do
      let(:body) { valid_payload.except(:labware).to_json }
      let!(:stored_operation) do
        create(:api_operation,
               api_application: integration_hub_app,
               external_id: 'request-1',
               payload: body,
               payload_digest: ApiOperation::PayloadDigest.hexdigest(body))
      end

      before { post_request(api_key: integration_hub_app.key) }

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the stored operation' do
        expect(json['operation_id']).to eq(stored_operation.uuid)
      end
    end

    context 'when a used request ID comes with a payload the schema rejects' do
      let(:body) { valid_payload.except(:labware).to_json }

      before do
        create(:api_operation, api_application: integration_hub_app,
                               external_id: 'request-1')
        post_request(api_key: integration_hub_app.key)
      end

      it 'returns conflict' do
        expect(response).to have_http_status(:conflict)
      end
    end

    context 'with the schema in a schema registry' do
      let(:registry_answer) do
        { subject: 'work-order-schema', version: 1, id: 1, schemaType: 'JSON',
          schema: Rails.root.join('config/schemas/json_schema/' \
                                  'work-order-schema/1.json').read }
      end

      before do
        allow(Rails.application.config)
          .to receive(:sapio_schema_source).and_return('redpanda')
        stub_request(:get, 'http://test-registry/subjects/' \
                           'work-order-schema/versions/latest')
          .to_return(body: registry_answer.to_json, headers: {
                       'Content-Type' =>
                         HTTPClients::SchemaRegistryClient::MEDIA_TYPE
                     })
        post_request(api_key: integration_hub_app.key)
      end

      it 'accepts a payload that matches it' do
        expect(response).to have_http_status(:accepted)
      end
    end

    context 'when the schema registry cannot be reached' do
      before do
        allow(Rails.application.config)
          .to receive(:sapio_schema_source).and_return('redpanda')
        stub_request(:get, %r{\Ahttp://test-registry/}).to_timeout
        allow(ExceptionNotifier).to receive(:notify_exception)
        post_request(api_key: integration_hub_app.key)
      end

      it 'returns service unavailable' do
        expect(response).to have_http_status(:service_unavailable)
      end

      it 'returns a schema unavailable error' do
        expect(json.dig('errors', 0, 'code')).to eq('SCHEMA_UNAVAILABLE')
      end

      it 'asks the caller to try again later' do
        expect(response.headers['Retry-After']).to eq('60')
      end

      it 'reports the cause' do
        expect(ExceptionNotifier).to have_received(:notify_exception)
          .with(an_instance_of(Schemas::Source::Unavailable), data: anything)
      end

      it 'does not save an operation' do
        expect(ApiOperation.count).to eq(0)
      end
    end

    # The drafts allow only one request type, so the schema check is stubbed
    # to accept another one.
    context 'with another request type' do
      let(:body) do
        valid_payload.deep_merge(request: { request_type: 'reception' }).to_json
      end

      before do
        allow(ApiOperation::SchemaCheck).to receive(:new)
          .and_return(instance_double(ApiOperation::SchemaCheck, valid?: true))
        post_request(api_key: integration_hub_app.key)
      end

      it 'stores it as the operation type' do
        expect(ApiOperation.last.operation_type).to eq('reception')
      end
    end

    # A version the test schemas don't have, so the schema can't be loaded
    context 'when the schema cannot be loaded' do
      before do
        allow(Rails.application.config)
          .to receive(:sapio_schema_version).and_return('99')
        allow(ExceptionNotifier).to receive(:notify_exception)
        post_request(api_key: integration_hub_app.key)
      end

      it 'returns internal server error' do
        expect(response).to have_http_status(:internal_server_error)
      end

      it 'returns a schema unavailable error' do
        expect(json.dig('errors', 0, 'code')).to eq('SCHEMA_UNAVAILABLE')
      end

      it 'does not show the cause to the caller' do
        expect(json.dig('errors', 0, 'detail'))
          .to eq('The payload schema could not be loaded.')
      end

      it 'does not ask the caller to try again later' do
        expect(response.headers).not_to have_key('Retry-After')
      end

      it 'reports the cause' do
        expect(ExceptionNotifier).to have_received(:notify_exception).with(
          an_instance_of(Schemas::Source::NotFound),
          data: hash_including(external_id: 'request-1')
        )
      end

      it 'does not save an operation' do
        expect(ApiOperation.count).to eq(0)
      end

      it 'does not queue a job' do
        expect(Delayed::Job.count).to eq(0)
      end
    end

    context 'when a stored request is repeated and the schema cannot load' do
      let!(:stored_operation) do
        create(:api_operation,
               api_application: integration_hub_app,
               external_id: 'request-1',
               payload: body,
               payload_digest: ApiOperation::PayloadDigest.hexdigest(body))
      end

      before do
        allow(Rails.application.config)
          .to receive(:sapio_schema_version).and_return('99')
        post_request(api_key: integration_hub_app.key)
      end

      it 'returns the stored operation' do
        expect(json['operation_id']).to eq(stored_operation.uuid)
      end
    end

    # A unique index error with no earlier operation for this request ID is
    # not a repeat, so it is raised again rather than answered.
    context 'when saving hits a unique index without an earlier operation' do
      before do
        allow(ApiOperation).to receive(:create_with_job!)
          .and_raise(ActiveRecord::RecordNotUnique)
      end

      it 'raises the error' do
        expect { post_request(api_key: integration_hub_app.key) }
          .to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    # Two requests with the same request ID race: this request's lookup
    # finds nothing, but the other request's operation is saved before this
    # one, so the unique index rejects this one.
    context 'when another request with the same ID wins a race' do
      let(:other_body) { body }
      let!(:other_operation) do
        digest = ApiOperation::PayloadDigest.hexdigest(other_body)
        create(:api_operation,
               api_application: integration_hub_app,
               external_id: 'request-1',
               payload: other_body,
               payload_digest: digest)
      end

      before do
        lookups = 0
        allow(ApiOperation).to receive(:find_by)
          .and_wrap_original do |original, *args, **kwargs|
            lookups += 1
            lookups == 1 ? nil : original.call(*args, **kwargs)
          end
        post_request(api_key: integration_hub_app.key)
      end

      context 'with the same payload' do
        it 'returns ok' do
          expect(response).to have_http_status(:ok)
        end

        it 'returns the other operation' do
          expect(json['operation_id']).to eq(other_operation.uuid)
        end

        it 'does not save another operation' do
          expect(ApiOperation.count).to eq(1)
        end

        it 'does not queue a job' do
          expect(Delayed::Job.count).to eq(0)
        end
      end

      context 'with a different payload' do
        let(:other_body) do
          valid_payload.deep_merge(work_order: { external_id: 'REQ1' })
            .to_json
        end

        it 'returns conflict' do
          expect(response).to have_http_status(:conflict)
        end

        it 'does not save another operation' do
          expect(ApiOperation.count).to eq(1)
        end

        it 'does not queue a job' do
          expect(Delayed::Job.count).to eq(0)
        end
      end
    end

    context 'with the Integration Hub API key' do
      before { post_request(api_key: integration_hub_app.key) }

      it 'returns accepted' do
        expect(response).to have_http_status(:accepted)
      end

      it 'returns the operation ID and status' do
        expect(json).to eq(
          'operation_id' => ApiOperation.last.uuid, 'status' => 'queued'
        )
      end

      it 'queues one coordinator job for the operation' do
        expect(Delayed::Job.all.map(&:payload_object))
          .to eq([ApiOperation::CoordinatorJob.new(ApiOperation.last.id)])
      end

      context 'when the same request is sent again' do
        let!(:first_response) { response.parsed_body }

        before { post_request(api_key: integration_hub_app.key) }

        it 'returns ok' do
          expect(response).to have_http_status(:ok)
        end

        it 'returns the existing operation ID and status' do
          expect(json).to eq(first_response)
        end

        it 'does not save another operation' do
          expect(ApiOperation.count).to eq(1)
        end

        it 'queues no job beyond the first request' do
          expect(Delayed::Job.count).to eq(1)
        end
      end

      context 'when the same payload is sent again in another layout' do
        let!(:first_response) { response.parsed_body }

        before do
          post_request(api_key: integration_hub_app.key,
                       request_body: JSON.pretty_generate(valid_payload))
        end

        it 'returns ok' do
          expect(response).to have_http_status(:ok)
        end

        it 'returns the existing operation' do
          expect(json['operation_id']).to eq(first_response['operation_id'])
        end

        it 'does not save another operation' do
          expect(ApiOperation.count).to eq(1)
        end

        it 'queues no job beyond the first request' do
          expect(Delayed::Job.count).to eq(1)
        end
      end

      context 'when the request ID is sent again with a different payload' do
        let(:first_body) { body }

        before do
          changed =
            valid_payload.deep_merge(work_order: { external_id: 'REQ1' })
          post_request(api_key: integration_hub_app.key,
                       request_body: changed.to_json)
        end

        it 'returns conflict' do
          expect(response).to have_http_status(:conflict)
        end

        it 'returns a payload conflict error' do
          expect(json.dig('errors', 0, 'code')).to eq('PAYLOAD_CONFLICT')
        end

        it 'points to the request ID' do
          expect(json.dig('errors', 0, 'source', 'pointer'))
            .to eq('/request/external_id')
        end

        it 'does not save another operation' do
          expect(ApiOperation.count).to eq(1)
        end

        it 'queues no job beyond the first request' do
          expect(Delayed::Job.count).to eq(1)
        end

        it 'does not change the existing operation' do
          expect(ApiOperation.last.payload).to eq(first_body)
        end
      end

      describe 'the saved operation' do
        let(:operation) { ApiOperation.last }

        it 'saves one operation' do
          expect(ApiOperation.count).to eq(1)
        end

        it 'belongs to the Integration Hub application' do
          expect(operation.api_application).to eq(integration_hub_app)
        end

        it 'stores the request ID' do
          expect(operation.external_id).to eq('request-1')
        end

        it 'stores the request type as the operation type' do
          expect(operation.operation_type).to eq('reception_and_work_order')
        end

        it 'stores the payload digest' do
          expect(operation.payload_digest)
            .to eq(ApiOperation::PayloadDigest.hexdigest(body))
        end

        it 'starts as queued' do
          expect(operation.status).to eq('queued')
        end

        context 'with a pretty-printed body' do
          let(:body) { JSON.pretty_generate(valid_payload) }

          it 'stores the payload exactly as sent' do
            expect(operation.payload).to eq(body)
          end
        end

        context 'without a work order' do
          let(:body) { valid_payload.except(:work_order).to_json }

          it 'saves the operation' do
            expect(operation.payload).to eq(body)
          end
        end
      end

      context 'with invalid JSON' do
        let(:body) { '{"request": ' }

        it 'returns bad request' do
          expect(response).to have_http_status(:bad_request)
        end

        it 'returns an invalid JSON error' do
          expect(json.dig('errors', 0, 'code')).to eq('INVALID_JSON')
        end

        it 'does not save an operation' do
          expect(ApiOperation.count).to eq(0)
        end

        it 'does not queue a job' do
          expect(Delayed::Job.count).to eq(0)
        end
      end

      context 'with an empty body' do
        let(:body) { '' }

        it 'returns bad request' do
          expect(response).to have_http_status(:bad_request)
        end

        it 'does not save an operation' do
          expect(ApiOperation.count).to eq(0)
        end

        it 'does not queue a job' do
          expect(Delayed::Job.count).to eq(0)
        end
      end

      # Each case changes the valid payload and names the expected pointer.
      {
        'a body that is not an object' => [->(_) { [] }, ''],
        'no request section' =>
          [->(p) { p.except(:request) }, '/request/external_id'],
        'a request section that is not an object' =>
          [->(p) { p.merge(request: 'request-1') }, '/request/external_id'],
        'an empty external ID' =>
          [->(p) { p.merge(request: { external_id: '' }) },
           '/request/external_id'],
        'an external ID that is not a string' =>
          [->(p) { p.merge(request: { external_id: 1 }) },
           '/request/external_id']
      }.each do |description, (change, pointer)|
        context "with #{description}" do
          let(:body) { change.call(valid_payload).to_json }

          it 'returns unprocessable content' do
            expect(response).to have_http_status(:unprocessable_content)
          end

          it 'returns an invalid structure error' do
            expect(json.dig('errors', 0, 'code')).to eq('INVALID_STRUCTURE')
          end

          it 'points to the problem' do
            expect(json.dig('errors', 0, 'source', 'pointer')).to eq(pointer)
          end

          it 'does not save an operation' do
            expect(ApiOperation.count).to eq(0)
          end

          it 'does not queue a job' do
            expect(Delayed::Job.count).to eq(0)
          end
        end
      end

      context 'with an empty object' do
        let(:body) { {}.to_json }

        it 'returns one error, for the request ID' do
          pointers =
            json['errors'].map { |error| error.dig('source', 'pointer') }
          expect(pointers).to eq(%w[/request/external_id])
        end
      end

      # Each case changes the valid payload so that it doesn't match the
      # schema, and names the expected pointer.
      {
        'no labware section' => [->(p) { p.except(:labware) }, ''],
        'a labware section that is not an array' =>
          [->(p) { p.merge(labware: {}) }, '/labware'],
        'a work order section that is not an object' =>
          [->(p) { p.merge(work_order: []) }, '/work_order'],
        'an unknown labware type' =>
          [->(p) { p.merge(labware: [p[:labware].first.merge(type: 'vial')]) },
           '/labware/0/type']
      }.each do |description, (change, pointer)|
        context "with #{description}" do
          let(:body) { change.call(valid_payload).to_json }

          it 'returns unprocessable content' do
            expect(response).to have_http_status(:unprocessable_content)
          end

          it 'returns a schema validation error' do
            expect(json.dig('errors', 0, 'code'))
              .to eq('SCHEMA_VALIDATION_FAILED')
          end

          it 'points to the problem' do
            expect(json.dig('errors', 0, 'source', 'pointer')).to eq(pointer)
          end

          it 'names the schema and version used' do
            expect(json.dig('errors', 0, 'meta')).to eq(
              'schema' => 'work-order-schema',
              'version' => schema_validator.schema.version
            )
          end

          it 'does not save an operation' do
            expect(ApiOperation.count).to eq(0)
          end

          it 'does not queue a job' do
            expect(Delayed::Job.count).to eq(0)
          end
        end
      end

      context 'with a payload that has one schema problem' do
        let(:body) { valid_payload.except(:labware).to_json }

        it 'counts the errors' do
          expect(json['meta']).to eq('errors_total' => 1, 'errors_shown' => 1)
        end
      end

      context 'with more schema problems than are returned' do
        let(:body) do
          bad_labware = valid_payload[:labware].first.merge(type: 'vial')
          valid_payload.merge(labware: [bad_labware] * 3).to_json
        end

        before do
          stub_const('ApiOperation::SchemaCheck::MAX_PROBLEMS', 2)
          post_request(api_key: integration_hub_app.key)
        end

        it 'returns only the first errors' do
          expect(json['errors'].size).to eq(2)
        end

        it 'counts all the errors' do
          expect(json['meta']).to eq('errors_total' => 3, 'errors_shown' => 2)
        end
      end
    end
  end
end
