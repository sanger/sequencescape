# frozen_string_literal: true

# Checks the payload before reception creates anything, and collects every
# problem, each with a pointer into the payload. Each group of rules is a
# check (a Validation::Check), and the checks run in the order of CHECKS.
# Known labware is checked by ApiOperation::Reception::Reconciliation
# instead, and its samples are not stored, so the checks look at the new
# labware and its samples.
class ApiOperation::Reception::Validation
  # The checks, in the order their problems are reported
  CHECKS = [LabwareCheck, SampleCheck, TagCheck, LibraryCheck].freeze

  # @param payload_labware [Array<ApiOperation::Reception::Payload::
  #   PayloadLabware>] all the payload's labware
  # @param new_labware [Array<ApiOperation::Reception::Payload::
  #   PayloadLabware>] the payload labware Sequencescape doesn't have
  def initialize(payload_labware, new_labware)
    @input = Input.build(payload_labware, new_labware)
  end

  # @return [Array<Hash>] the problems, each with a :pointer and a :detail
  def errors
    @errors ||= CHECKS.flat_map { |check| check.new(@input).errors }
  end
end
