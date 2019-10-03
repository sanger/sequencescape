# @deprecated Part of the old Generic Lims pipelines
# Plate in the old Generic Lims pipelines. Used by:
#
# - ILC Lib PCR
#
# @todo #2396 Remove this class. This will require:
#
#       - Update any purposes using this class to use PlatePurpose instead
#       - Update:
#           app/models/illumina_c/plate_purposes.rb
#         By either replacing with PlatePurpose, or removing the factories entirely
class IlluminaC::LibPcrPurpose < PlatePurpose
  include PlatePurpose::Library

  alias_method(:default_transition_to, :transition_to)

  # Updates the state of plate to state
  # @param plate [Plate] The plate being updated
  # @param state [String] The desired target state
  # @param user [User] The person to associate with the action (Will take ownership of the plate)
  # @param contents [nil, Array] Array of well locations to update, leave nil for ALL wells
  # @param customer_accepts_responsibility [Boolean] The customer proceeded against advice and will still be charged
  #                                                  in the the event of a failure
  #
  # @return [Void]
  def transition_to(plate, state, user, contents = nil, customer_accepts_responsibility = false)
    nudge_parent_plate(plate, state, user, contents)
    default_transition_to(plate, state, user, contents, customer_accepts_responsibility)
  end

  def nudge_parent_plate(plate, state, user, contents)
    plate.parent.transition_to(state, user, contents) if %w[started passed].include?(state)
  end
  private :nudge_parent_plate
end
