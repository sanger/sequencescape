# frozen_string_literal: true

# Receives the labware and samples in an operation's payload: labware already
# in Sequencescape is matched and left unchanged, and the rest is validated
# and created. ApiOperation::CoordinatorJob runs it, in a transaction, when
# the y26_283_sapio_reception feature flag is on, and records the outcome.
#
# All problems are collected: known labware that isn't the same (conflicts),
# and problems with the payload's labware (validation). Later steps add more
# checks and create the new labware.
class ApiOperation::Reception
  # @param api_operation [ApiOperation] the operation to receive
  def initialize(api_operation)
    @api_operation = api_operation
  end

  # Receives the operation's labware and samples.
  #
  # @return [Array<Hash>] the errors, each with a :detail, and a :pointer
  #   when it is about something in the payload; empty if reception
  #   succeeded
  def call
    reconciliation.errors + validation.errors
  end

  private

  def validation
    @validation ||=
      ApiOperation::Reception::Validation
        .new(payload.labware, reconciliation.new_labware)
  end

  def reconciliation
    @reconciliation ||=
      ApiOperation::Reception::Reconciliation.new(payload.labware)
  end

  def payload
    @payload ||= ApiOperation::Reception::Payload.new(@api_operation.payload)
  end
end
