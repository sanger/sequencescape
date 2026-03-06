# frozen_string_literal: true

module Cherrypick::Task::BufferVolumeForEmptyWellsOption
  def create_buffer_volume_for_empty_wells_option(params)
    return unless @batch

    key = :automatic_buffer_addition
    # The checkbox value is either "1", or nil if not checked.
    @batch.set_poly_metadata(key, params[key])

    return unless %w[1 on].include?(params[key])

    # If automatic buffer addition for empty wells is required, check and
    # set the required buffer volume in the batch polymetadata.
    key = :buffer_volume_for_empty_wells

    # method valid_float_param? is defined in Cherrypick::Task::PickHelpers
    unless valid_float_param?(params[key])
      raise Cherrypick::VolumeError,
            "Invalid buffer volume for empty wells: #{params[key]}"
    end

    @batch.set_poly_metadata(key, params[key])
  end
end
