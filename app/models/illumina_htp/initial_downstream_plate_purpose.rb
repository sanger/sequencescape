# @deprecated Part of the old Illumina-B ISC pipeline
#
# First plate downstream of PCR-XP plate when using a plate pooling strategy
#
# - Lib Norm
#
# @todo #2396 Remove this class. This will require:
#       - Also remove subclass {Pulldown::InitialDownstreamPlatePurpose}
#       - Update any purposes using this class to use PlatePurpose instead
#       - Update:
#           app/models/illumina_htp/plate_purposes.rb
#         By either replacing with PlatePurpose, or removing the factories entirely
class IlluminaHtp::InitialDownstreamPlatePurpose < IlluminaHtp::DownstreamPlatePurpose
  # Initial plates in the pulldown pipelines change the state of the pulldown requests they are being
  # created for to exactly the same state.
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
    ActiveRecord::Base.transaction do
      super
      new_outer_state = %w[started passed qc_complete].include?(state) ? 'started' : state

      # CAUTION!
      # TODO: While the behaviour here wont cause us any issues, its actually subtly wrong.
      # 1) Multiple wells on the same plate may have the same stock wells
      # 2) Well location may change between parent and child plates.
      # 3) As we only fire on pending requests this isn't actually a massive problem as we'll be targeting the whole plate anyway
      active_submissions = plate.submission_ids

      stock_wells(plate, contents).each do |source_well|
        # Only transitions from last submission
        source_well.requests.select { |r| r.library_creation? && active_submissions.include?(r.submission_id) }.each do |request|
          request.transition_to(new_outer_state) if request.pending?
        end
      end
    end
  end

  def stock_wells(plate, contents)
    return plate.parent.wells if contents.blank?

    plate.parent.wells.located_at(contents)
  end
end
