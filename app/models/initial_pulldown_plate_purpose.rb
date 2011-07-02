# Specialised implementation of the plate purpose for the initial plate types in the Pulldown pipelines:
# WGS fragmentation plate, SC fragmentation plate, ISC fragmentation plate.
class InitialPulldownPlatePurpose < PlatePurpose
  # Initial plates in the pulldown pipelines change the state of the pulldown requests they are being
  # created for to exactly the same state.
  def transition_to(plate, state, contents = nil)
    super

    plate.wells.each do |well|
      transfer_request = well.transfer_requests_as_target.first or next
      library_request  = transfer_request.asset.requests_as_source.where_is_a?(PulldownLibraryCreationRequest).first
      start_pulldown_library_request(library_request)
      assign_library_information(well, library_request) if [ 'started', 'passed' ].include?(state)
    end
  end

  # Ensure that the pulldown library creation request is started
  def start_pulldown_library_request(request)
    request.update_attributes!(:state => 'started')
  end
  private :start_pulldown_library_request

  # Ensure that the library information within the aliquots of the well is correct.
  def assign_library_information(well, library_request)
    insert_size = library_request.insert_size

    well.aliquots.each do |aliquot|
      aliquot.library     ||= well
      aliquot.insert_size ||= insert_size
      aliquot.save!
    end
  end
  private :assign_library_information
end
