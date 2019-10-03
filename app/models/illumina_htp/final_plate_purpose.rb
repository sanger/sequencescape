# @deprecated Part of the old Illumina-B Lims pipelines
# Plate type used at the end of a pipeline
#
# - Lib PCR-XP
# - Lib PCRR-XP
#
# @todo #2396 Remove this class. This will require:
#
#       - Update any purposes using this class to use PlatePurpose instead
#       - Also remove the subclass {IlluminaHtp::TransferablePlatePurpose}
#       - Update:
#           app/models/illumina_htp/plate_purposes.rb
#         By either replacing with PlatePurpose, or removing the factories entirely
class IlluminaHtp::FinalPlatePurpose < PlatePurpose
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
    nudge_pre_pcr_wells(plate, state, user, contents, customer_accepts_responsibility)
    default_transition_to(plate, state, user, contents, customer_accepts_responsibility)
  end

  def attatched?(plate)
    plate.state == ('qc_complete')
  end

  def fail_stock_well_requests(wells, _)
    # Handled by the nudge of the pre PCR wells!
  end
  private :fail_stock_well_requests

  def nudge_pre_pcr_wells(plate, state, user, contents, customer_accepts_responsibility)
    plate.parent.parent.transition_to(state, user, contents, customer_accepts_responsibility) if state == 'failed'
  end
  private :nudge_pre_pcr_wells
end

require_dependency 'illumina_htp/transferable_plate_purpose'
