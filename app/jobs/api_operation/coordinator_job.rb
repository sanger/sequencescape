# frozen_string_literal: true

# Processes an API operation in the background, according to its type;
# for a combined reception and work order request, its reception, then its
# work order. The job is saved in the same transaction as the operation, so
# every saved operation has its job.
#
# With the y26_283_sapio_reception feature flag on, it runs the reception
# (ApiOperation::Reception); with the flag off, it only logs that the
# operation is ready. Work order processing is added by Y26-289.
ApiOperation::CoordinatorJob =
  Struct.new(:api_operation_id) do
    # Delayed Job calls this to run the job.
    #
    # @return [void]
    def perform
      api_operation = ApiOperation.find(api_operation_id)
      if Flipper.enabled?(:y26_283_sapio_reception)
        ApiOperation::Reception.new(api_operation).call
      else
        Rails.logger.info(
          "ApiOperation #{api_operation.uuid} is ready for processing"
        )
      end
    end
  end
