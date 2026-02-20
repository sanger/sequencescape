# frozen_string_literal: true
module Batch::PolyMetadataBehaviour
  # Returns whether the Cherrypick automatic_buffer_addition option is enabled
  # @return [Boolean] whether the automatic_buffer_addition option is enabled
  def automatic_buffer_addition?
    get_poly_metadata(:automatic_buffer_addition) == '1'
  end

  # Returns the Cherrypick buffer_volume_for_empty_wells option value if
  # automatic_buffer_addition is enabled, nil otherwise.
  # @return [Float, nil] the buffer_volume_for_empty_wells value
  def buffer_volume_for_empty_wells
    get_poly_metadata(:buffer_volume_for_empty_wells).to_f if automatic_buffer_addition?
  end
end
