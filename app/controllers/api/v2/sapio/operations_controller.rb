# frozen_string_literal: true

module Api
  module V2
    module Sapio
      # Receives combined reception and work order requests from Integration
      # Hub.
      #
      # The payload is plain JSON rather than JSON:API, so this is a plain
      # controller rather than a JSON:API resource controller.
      #
      # The endpoint is behind the +y26_282_sapio_operations_endpoint+
      # feature flag and accepts requests only with the Integration Hub API
      # key.
      class OperationsController < ApplicationController
        include Api::V2::Concerns::ApiKeyAuthenticatable

        skip_before_action :login_required
        skip_before_action :verify_authenticity_token
        # This filter reads params, which makes Rails parse the body and
        # raise its own error for invalid JSON. The body is parsed in
        # parse_payload instead.
        skip_before_action :extract_header_info

        # Payloads can be many megabytes, so Rails shouldn't add a copy of
        # them under the controller name.
        wrap_parameters false

        before_action :check_endpoint_enabled
        before_action :authorize_integration_hub
        before_action :parse_payload
        before_action :check_structure

        # Matches every parameter name except the routing ones, so the
        # payload is logged as [FILTERED].
        PAYLOAD_LOG_FILTER = /\A(?!(?:controller|action|format)\z)/

        # The kind of operation this endpoint creates
        OPERATION_TYPE = 'reception_and_work_order'

        NOT_AN_OBJECT = 'The request body must be a JSON object.'

        # The top level checks: JSON pointer, error detail and check method.
        STRUCTURE_RULES = [
          [
            '/request/external_id',
            'request.external_id must be a non-empty string.',
            :external_id_present?
          ],
          ['/labware', 'labware must be an array.', :labware_present?],
          ['/work_order', 'work_order must be an object.', :work_order_present?]
        ].freeze

        # Accepts a combined reception and work order request.
        #
        # @return [void]
        def create
          create_operation
          render json: {}, status: :accepted
        end

        private

        # Adds PAYLOAD_LOG_FILTER to this request's parameter filters before
        # Rails logs the parameters, which happens before any before_action.
        # The global filters are kept, and other endpoints are not affected.
        #
        # @return [void]
        def process_action(*)
          filters = request.get_header('action_dispatch.parameter_filter')
          request.set_header('action_dispatch.parameter_filter',
                             Array(filters) + [PAYLOAD_LOG_FILTER])
          super
        end

        # Renders a not found error unless the feature flag is enabled.
        #
        # @return [void]
        def check_endpoint_enabled
          return if Flipper.enabled?(:y26_282_sapio_operations_endpoint)

          render_errors(Errors::FeatureDisabled.new.errors)
        end

        # Renders a forbidden error unless the request uses the Integration
        # Hub API key.
        #
        # @return [void]
        def authorize_integration_hub
          return if api_application&.integration_hub?

          render_errors(Errors::Forbidden.new.errors)
        end

        # Parses the raw request body, so the payload is exactly what was
        # sent. Renders a bad request error if the body is not valid JSON.
        #
        # @return [void]
        def parse_payload
          @payload = JSON.parse(request.raw_post)
        rescue JSON::ParserError
          render_errors(Errors::InvalidJson.new.errors)
        end

        # Renders an error for each problem with the top level of the
        # payload: the request ID and the reception and work order
        # sections. The contents of the sections are not checked here.
        #
        # @return [void]
        def check_structure
          errors = structure_errors
          render_errors(errors) if errors.any?
        end

        # @return [Array<JSONAPI::Error>] the top level problems, if any
        def structure_errors
          return structure_error('', NOT_AN_OBJECT) unless @payload.is_a?(Hash)

          STRUCTURE_RULES.flat_map do |pointer, detail, check|
            send(check) ? [] : structure_error(pointer, detail)
          end
        end

        # @return [Boolean] true if request.external_id is a non-empty string
        def external_id_present?
          request_section = @payload['request']
          return false unless request_section.is_a?(Hash)

          external_id = request_section['external_id']
          external_id.is_a?(String) && external_id.present?
        end

        # @return [Boolean] true if the reception section is an array
        def labware_present?
          @payload['labware'].is_a?(Array)
        end

        # @return [Boolean] true if the work order section is an object
        def work_order_present?
          @payload['work_order'].is_a?(Hash)
        end

        # @param pointer [String] JSON pointer to the problem
        # @param detail [String] description of the problem
        # @return [Array<JSONAPI::Error>]
        def structure_error(pointer, detail)
          Errors::InvalidStructure.new(pointer, detail).errors
        end

        # Saves the request as an operation, with the raw body as its
        # payload. The task statuses start as pending.
        #
        # @return [ApiOperation] the saved operation
        def create_operation
          payload = request.raw_post
          ApiOperation.create!(
            api_application: api_application,
            external_id: @payload.dig('request', 'external_id'),
            work_order_external_id: work_order_external_id,
            operation_type: OPERATION_TYPE,
            payload: payload,
            payload_digest: ApiOperation::PayloadDigest.hexdigest(payload)
          )
        end

        # @return [String, nil] work_order.external_id, if it is a string;
        #   it is stored but not used yet
        def work_order_external_id
          external_id = @payload['work_order']['external_id']
          external_id if external_id.is_a?(String)
        end

        # Renders JSON:API style errors with the status of the first error.
        #
        # @param errors [Array<JSONAPI::Error>] the errors to render
        # @return [void]
        def render_errors(errors)
          render json: { errors: errors.map(&:to_hash) },
                 status: errors.first.status.to_i
        end
      end
    end
  end
end
