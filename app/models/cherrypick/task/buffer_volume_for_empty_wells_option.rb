# frozen_string_literal: true

module Cherrypick::Task::BufferVolumeForEmptyWellsOption
  # rubocop:disable Metrics/MethodLength
  def create_buffer_volume_for_empty_wells_option(params)
    return unless @batch

    key = :automatic_buffer_addition

    # The checkbox value is either '1', 'on' or nil if not checked.
    # Store a consistent value
    value = %w[1 on].include?(params[key]) ? '1' : params[key]
    @batch.set_poly_metadata(key, value)

    if value == '1'
      record_buffer_addition_volume(params)
      record_plate_template_for_buffer_addition(params)
    else
      clear_buffer_addition_volume(params)
      clear_plate_template_for_buffer_addition(params)
    end
  end

  # rubocop:enable Metrics/MethodLength

  private

  def record_buffer_addition_volume(params)
    key = :buffer_volume_for_empty_wells

    unless valid_float_param?(params[key])
      raise Cherrypick::VolumeError,
            "Invalid buffer volume for empty wells: #{params[key]}"
    end
    @batch.set_poly_metadata(key, params[key])
  end

  # From selection box in GUI, so should not require validation
  def record_plate_template_for_buffer_addition(params)
    key = :plate_template_for_buffer_addition

    @batch.set_poly_metadata(key, params[key])
  end

  # Most likely it's not set, but if it is, clear it to avoid confusion.
  def clear_buffer_addition_volume(_params)
    return if @batch.get_poly_metadata(:buffer_volume_for_empty_wells).blank?

    @batch.set_poly_metadata(:buffer_volume_for_empty_wells, nil)
  end

  # Most likely it's not set, but if it is, clear it to avoid confusion.
  def clear_plate_template_for_buffer_addition(_params)
    return if @batch.get_poly_metadata(:plate_template_for_buffer_addition).blank?

    @batch.set_poly_metadata(:plate_template_for_buffer_addition, nil)
  end
end
