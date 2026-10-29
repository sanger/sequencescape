# frozen_string_literal: true
module Api
  module V2
    module Concerns
      # Responses for a payload checked with ApiOperation::SchemaCheck:
      # - A payload that doesn't match the schema gets a 422 with the first
      #   problems and their total.
      # - If the schema can't be loaded, the caller gets a 500, and the
      #   cause, a configuration problem, is reported to the team only. If
      #   the schema's source can't be reached, it gets a 503 with
      #   Retry-After instead.
      #
      # The including controller provides render_errors and external_id.
      module SchemaCheckable
        extend ActiveSupport::Concern

        # Seconds the caller is asked to wait before trying again when the
        # schema's source can't be reached
        RETRY_AFTER = 60

        included do
          rescue_from Schemas::Error, with: :render_schema_unavailable
        end

        private

        # Renders the problems the schema check kept, with the total.
        #
        # @param check [ApiOperation::SchemaCheck]
        # @return [void]
        def render_schema_errors(check)
          errors =
            Api::V2::Sapio::Errors::SchemaValidationFailed
              .new(check.problems, check.schema_meta).errors
          render_errors(errors, meta: { errors_total: check.total,
                                        errors_shown: check.problems.size })
        end

        # Reports why the schema couldn't be loaded and renders a server
        # error: 503 with Retry-After when its source can't be reached, as
        # that can pass, otherwise 500.
        #
        # @param error [Schemas::Error]
        # @return [void]
        def render_schema_unavailable(error)
          ExceptionNotifier.notify_exception(
            error, data: { message: 'Sapio operation schema unavailable',
                           external_id: external_id }
          )
          temporary = error.is_a?(Schemas::Source::Unavailable)
          response.set_header('Retry-After', RETRY_AFTER.to_s) if temporary
          render_errors(Api::V2::Sapio::Errors::SchemaUnavailable
                          .new(temporary:).errors)
        end
      end
    end
  end
end
