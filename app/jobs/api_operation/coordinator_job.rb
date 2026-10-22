# frozen_string_literal: true

# Processes an API operation in the background: its reception task, then
# its work order task. The job is saved in the same transaction as the
# operation, so every saved operation has its job.
#
# This placeholder only logs that the operation is ready. Reception and
# work order processing are added by later stories (Y26-283 and Y26-289).
ApiOperation::CoordinatorJob =
  Struct.new(:api_operation_id) do
    # Delayed Job calls this to run the job.
    #
    # @return [void]
    def perform
      api_operation = ApiOperation.find(api_operation_id)
      Rails.logger.info(
        "ApiOperation #{api_operation.uuid} is ready for processing"
      )
    end
  end
