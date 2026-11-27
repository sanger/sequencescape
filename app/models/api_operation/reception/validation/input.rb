# frozen_string_literal: true

# What every check is given: all the payload's labware, the payload labware
# Sequencescape doesn't have, and the samples in that new labware, with an
# entry for each receptacle a sample is in.
ApiOperation::Reception::Validation::Input =
  Data.define(:payload_labware, :new_labware, :new_samples) do
    # @param payload_labware [Array<ApiOperation::Reception::Payload::
    #   PayloadLabware>] all the payload's labware
    # @param new_labware [Array<ApiOperation::Reception::Payload::
    #   PayloadLabware>] the payload labware Sequencescape doesn't have
    # @return [ApiOperation::Reception::Validation::Input]
    def self.build(payload_labware, new_labware)
      new(payload_labware: payload_labware, new_labware: new_labware,
          new_samples: new_labware.flat_map(&:receptacles).flat_map(&:samples))
    end
  end
