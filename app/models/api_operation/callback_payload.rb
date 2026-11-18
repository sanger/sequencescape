# frozen_string_literal: true

# The outcome of a finished ApiOperation, as sent to the calling system by
# ApiOperation::CallbackJob. It is built from the operation's stored status
# and error details alone, so sending it never reruns a task.
#
#   { operation_type: 'reception_and_work_order',
#     external_id: 'request-1', # the calling system's request ID, the same in every send
#     status: 'work_order_failed', # the last completed or failed task, see ApiOperation
#     errors: [{ 'pointer' => '/work_order/cost_code', 'detail' => '...' }] } # only when a task failed
class ApiOperation::CallbackPayload
  # @param api_operation [ApiOperation] a finished operation
  def initialize(api_operation)
    @api_operation = api_operation
  end

  # @return [Hash] the payload, with symbol keys
  def to_h
    payload = {
      operation_type: @api_operation.operation_type,
      external_id: @api_operation.external_id,
      status: @api_operation.status
    }
    errors = @api_operation.error_details&.fetch('errors', nil)
    payload[:errors] = errors if errors.present?
    payload
  end
end
