# frozen_string_literal: true
#
# Class to support a different state machine for inputs added
# in the middle of a workflow
class PlatePurpose::AdditionalInput < PlatePurpose
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

    plate.wells.with_contents.all? do |well|
      return false if well.requests.empty?

      well
        .requests
        .filter { |a| !a.is_a?(CreateAssetRequest) }
        .all? { |request| request.is_a?(Request::LibraryCreation) || request.is_a?(LibraryCreationRequest) }
    end
  end
end
