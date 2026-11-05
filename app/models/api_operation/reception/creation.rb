# frozen_string_literal: true

# Creates the payload's new labware, with its samples, once reconciliation
# and validation have found nothing wrong. ApiOperation::Reception runs it
# inside the coordinator's transaction, so what it creates commits with the
# operation's status, or not at all. Records are saved with save!, so their
# models' validations and callbacks run; a record its model rejects raises,
# which rolls everything back.
#
# It creates the labware (LabwareFactory), then the samples (SampleFactory),
# then puts the samples into the labware as aliquots (AliquotFactory), and
# records the volumes the samples give on their wells and tubes
# (VolumeQcFactory). The samples' studies are looked up once, for both
# samples and aliquots.
class ApiOperation::Reception::Creation
  # @param new_labware [Array<ApiOperation::Reception::Payload::
  #   PayloadLabware>] the payload labware Sequencescape doesn't have
  # @param api_operation [ApiOperation] the operation being received
  def initialize(new_labware, api_operation)
    @new_labware = new_labware
    @api_operation = api_operation
  end

  # Creates the new labware and its samples.
  #
  # @return [void]
  def call
    labware = LabwareFactory.new(@new_labware).call
    samples = SampleFactory.new(@new_labware, studies).call
    AliquotFactory.new(labware, samples, studies).call
    VolumeQcFactory.new(labware, @api_operation).call
  end

  private

  # The new samples' studies by UUID (both in lower case), looked up once
  def studies
    @studies ||= begin
      uuids = @new_labware.flat_map(&:receptacles).flat_map(&:samples)
        .map(&:study_uuid).uniq
      Study.with_uuid(uuids).includes(:uuid_object).index_by(&:uuid)
    end
  end
end
