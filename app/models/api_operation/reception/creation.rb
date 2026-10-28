# frozen_string_literal: true

# Creates the payload's new labware, with its samples, once reconciliation
# and validation have found nothing wrong. ApiOperation::Reception runs it
# inside the coordinator's transaction, so what it creates commits with the
# operation's status, or not at all. Records are saved with save!, so their
# models' validations and callbacks run; a record its model rejects raises,
# which rolls everything back.
class ApiOperation::Reception::Creation
  # @param new_labware [Array<ApiOperation::Reception::Payload::
  #   PayloadLabware>] the payload labware Sequencescape doesn't have
  def initialize(new_labware)
    @new_labware = new_labware
  end

  # Creates the new labware and its samples.
  #
  # @return [void]
  def call
  end
end
