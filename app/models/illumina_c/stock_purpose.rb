# @deprecated Part of the old Generic Lims pipelines
# Input plate in the old Generic Lims pipelines. Used by:
#
# - ILC Stock
#
# Allowed failure of wells prior to starting
#
# @todo #2396 Remove this class. This will require:
#
#       - Update any purposes using this class to use PlatePurpose instead
#       - Update:
#           app/models/illumina_c/plate_purposes.rb
#           illumina_htp/plate_purposes.rb
#         By either replacing with PlatePurpose, or removing the factories entirely
class IlluminaC::StockPurpose < PlatePurpose
  include PlatePurpose::Stock

  # Updates the state of plate to state
  # @param plate [Plate] The plate being updated
  # @param state [String] The desired target state
  # @param _user [User] The person to associate with the action (Ignored. Provided for api compatibility)
  # @param contents [nil, Array] Array of well locations to update, leave nil for ALL wells
  # @param _customer_accepts_responsibility [Boolean] The customer proceeded against advice and will still be charged
  #                                                  in the the event of a failure (Ignored. Provided for api compatibility)
  #
  # @return [Void]
  def transition_to(plate, state, _user, contents = nil, _customer_accepts_responsibility = false)
    return unless %w[failed cancelled].include?(state)

    plate.wells.located_at(contents).include_requests_as_target.include_requests_as_source.each do |well|
      well.requests.each { |r| r.send(transition_from(r.state)) if r.is_a?(IlluminaC::Requests::LibraryRequest) && transition_from(r.state) }
      well.transfer_requests_as_target.each { |r| r.transition_to('failed') }
    end
  end

  private

  def transition_from(state)
    { 'pending' => :cancel_before_started!, 'started' => :cancel! }[state]
  end

  def calculate_state_of_well(wells_states)
    cancelled = wells_states.delete('cancelled') if wells_states.count > 1
    return wells_states.first if wells_states.one?
    return :unready if wells_states.size > 1

    cancelled || :unready
  end
end
