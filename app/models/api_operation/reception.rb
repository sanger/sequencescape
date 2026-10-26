# frozen_string_literal: true

# Receives the labware and samples in an operation's payload: labware already
# in Sequencescape is matched and left unchanged, and the rest is validated
# and created in one transaction. ApiOperation::CoordinatorJob runs it when
# the y26_283_sapio_reception feature flag is on.
#
# This first version does nothing; later steps add the reception.
class ApiOperation::Reception
  # @param api_operation [ApiOperation] the operation to receive
  def initialize(api_operation)
    @api_operation = api_operation
  end

  # Receives the operation's labware and samples.
  #
  # @return [void]
  def call
  end
end
