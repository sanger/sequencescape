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

  # @return [Hash{Study => Array<Receptacle>}] the receptacles by their study; those
  #   without exactly one study are left out, see #study_errors
  def receptacles_by_study
    @receptacles_by_study ||= receptacles.group_by { |receptacle| one_study_of(receptacle) }.except(nil)
  end

  # @return [Array<ApiOperation::Error>] a problem for each receptacle without exactly one study
  def study_errors
    receptacles.filter_map do |receptacle|
      next if one_study_of(receptacle)

      found = studies_of(receptacle).map(&:name).to_sentence.presence || 'none'
      ApiOperation::Error.new(POINTER, 'Each requested receptacle must have samples from one study; ' \
                                       "found #{found} for #{receptacle.display_name}")
    end
  end

  private

  def one_study_of(receptacle)
    studies = studies_of(receptacle)
    studies.first if studies.one?
  end

  # The studies of the receptacle's aliquots, or if they have none, of its samples.
  def studies_of(receptacle)
    (receptacle.aliquots.filter_map(&:study).presence || receptacle.samples.flat_map(&:studies)).uniq
  end
end
