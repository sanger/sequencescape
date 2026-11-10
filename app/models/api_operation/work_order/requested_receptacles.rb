# frozen_string_literal: true

# The receptacles named by a work order's requested_labware_identifiers, found
# once so that every step of the work order (validation, plate purposes,
# feasibility) shares them rather than looking them up again.
class ApiOperation::WorkOrder::RequestedReceptacles
  POINTER = ApiOperation::WorkOrder::Validation::ReceptacleValidation::POINTER

  # @param identifiers [Array<String>] the requested labware identifiers
  def initialize(identifiers)
    @identifiers = Array(identifiers)
  end

  # @return [Array<ApiOperation::WorkOrder::Validation::ReceptacleValidation>] one
  #   per identifier, in the order requested
  def validations
    @validations ||=
      @identifiers.each_with_index.map do |identifier, index|
        ApiOperation::WorkOrder::Validation::ReceptacleValidation.new(identifier, pointer: "#{POINTER}/#{index}")
      end
  end

  # @return [Array<ApiOperation::Error>] the problems with the identifiers
  def errors
    validations.flat_map(&:errors)
  end

  # @return [Array<Array(String, Receptacle)>] each identifier that names a
  #   receptacle, with it, in the order requested
  def identified_receptacles
    @identified_receptacles ||=
      validations.filter_map { |validation| [validation.identifier, validation.receptacle] if validation.receptacle }
  end

  # @return [Array<Receptacle>] the receptacles the identifiers name
  def receptacles
    identified_receptacles.map(&:last)
  end

  # @return [Array<Plate>] the distinct plates the identifiers name; not tubes
  def plates
    @plates ||= receptacles.map(&:labware).grep(Plate).uniq
  end
end
