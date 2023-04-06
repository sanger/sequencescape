# frozen_string_literal: true
#
# Class to support a different state machine for inputs added
# in the middle of a workflow
class PlatePurpose::IntermediateInput < PlatePurpose
  READY_STATE = 'passed'
  def state_of(plate)
    return READY_STATE if valid_intermediate_input?(plate)
    super(plate)
  end

  def valid_intermediate_input?(plate)
    [plate.ancestors.count.zero?, library_creation?(plate)].all?
  end

  def library_creation?(plate)
    return false if plate.wells.with_contents.empty?
    plate.wells.with_contents.all? do |w|
      return false if w.requests.empty?
      w.requests.all? { |r| r.is_a?(Request::LibraryCreation) || r.is_a?(LibraryCreationRequest) }
    end
  end
end
