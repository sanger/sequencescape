# frozen_string_literal: true

# Handles POST requests to /bioscan_control_locations.
# This action has been migrated from the Lighthouse /pickings endpoint. The
# robot uses POST requests to get the locations of the positive and negative
# controls on the plate with the given barcode.
#
# Request JSON:
# {
#   "barcode": "plate_barcode",
#   "user": "robot_user",
#   "robot": "robot_name"
# }
#
# Response JSON:
# {
#   "barcode": "plate_barcode",
#   "positive_control": "well_description",
#   "negative_control": "well_description"
# }
#
# Error responses are returned as:
# {
#   "errors": ["error message"]
# }
#
# The controller validates:
# - Plate existence
# - Plate purpose
# - Plate has samples
# - Exactly one positive and one negative control
#
# If any validation fails, a JSON error response is returned. Error responses
# use the same format and HTTP 400 status codes as the original Lighthouse
# endpoint.
class BioscanControlLocationsController < ApplicationController
  # Error messages
  NO_PLATE_DATA = "There is no plate data for barcode '%<barcode>s'"
  INCORRECT_PURPOSE =
    "Incorrect purpose '%<purpose_name>s' for barcode '%<barcode>s'"
  NO_SAMPLES = "There are no samples for barcode '%<barcode>s'"
  INCORRECT_CONTROLS =
    'There should be only one positive and one negative control ' \
    "for barcode '%<barcode>s'"
  MISSING_CONTROLS =
    "Missing positive or negative control for barcode '%<barcode>s'"

  # Expected plate purpose
  BIOSCAN_PLATE_PURPOSE = 'LBSN-96 Lysate'

  # Control types
  PCR_POSITIVE = 'pcr positive'
  PCR_NEGATIVE = 'pcr negative'

  # Output JSON keys
  JS_BARCODE = 'barcode' # => plate barcode
  JS_POSITIVE_CONTROL = 'positive_control' # => well description
  JS_NEGATIVE_CONTROL = 'negative_control' # => well description

  # Login is not required.
  before_action :login_required, except: %i[create]

  # Handles post requests to /bioscan_control_locations to get the locations
  # of the positive and negative controls on the plate with the given barcode.
  # @return [void]
  def create
    control_locations
  end

  private

  # Renders the control locations for the plate specified by the barcode param
  # or renders an error response if validation fails.
  # @return [void]
  def control_locations
    plate = find_plate(params[:barcode])
    return unless plate

    return unless valid_plate_purpose?(plate)
    return unless plate_has_samples?(plate)

    control_info = build_control_info(plate)
    return unless single_controls?(control_info, plate.human_barcode)
    return unless both_controls?(control_info, plate.human_barcode)

    render_locations(control_info, plate.human_barcode)
  end

  # Renders the successful control locations response.
  # @param control_info [Hash{String => String}] mapping of well descriptions
  #   to control types
  # @param barcode [String] the plate barcode
  # @return [void]
  def render_locations(control_info, barcode)
    positive_location = control_info.key(PCR_POSITIVE)
    negative_location = control_info.key(PCR_NEGATIVE)
    locations = {
      JS_BARCODE => barcode,
      JS_POSITIVE_CONTROL => positive_location,
      JS_NEGATIVE_CONTROL => negative_location
    }
    render json: locations, status: :ok
  end

  # Renders an error response with the given message and status.
  # @param message [String] the error message
  # @param status [Symbol] the HTTP status symbol
  # @return [void]
  def render_error(message, status)
    render json: { errors: [message] }, status: status
  end

  # Finds a plate by barcode and renders an error if not found.
  # @param barcode [String] the barcode of the plate to find
  # @return [Plate, nil] Plate if found, or nil if not (error rendered)
  def find_plate(barcode)
    plate = Plate.find_by_barcode(barcode)
    if plate.blank?
      message = format(NO_PLATE_DATA, barcode:)
      render_error(message, :bad_request)
      return nil
    end
    plate
  end

  # Checks plate purpose and renders error if invalid.
  # @param plate [Plate] the plate to check
  # @return [Boolean] true if valid, false if not (error rendered)
  def valid_plate_purpose?(plate)
    if plate.purpose.name != BIOSCAN_PLATE_PURPOSE
      message = format(
        INCORRECT_PURPOSE,
        purpose_name: plate.purpose.name,
        barcode: plate.human_barcode
      )
      render_error(message, :bad_request)
      return false
    end
    true
  end

  # Checks if plate has samples, renders error if not.
  # @param plate [Plate] the plate to check
  # @return [Boolean] true if has samples, false if not (error rendered)
  def plate_has_samples?(plate)
    if plate.samples.empty?
      message = format(NO_SAMPLES, barcode: plate.human_barcode)
      render_error(message, :bad_request)
      return false
    end
    true
  end

  # Builds a hash of well descriptions to control types for the plate.
  # @param plate [Plate] the plate to inspect
  # @return [Hash{String => String}] well description => control type
  def build_control_info(plate)
    plate.wells.each_with_object({}) do |well, hash|
      aliquot = well.aliquots.find { |a| a.sample.present? }
      if aliquot &&
          [PCR_POSITIVE, PCR_NEGATIVE].include?(aliquot.sample.control_type)
        hash[well.map_description] = aliquot.sample.control_type
      end
    end
  end

  # Checks for single positive and negative control, renders error if not.
  # @param control_info [Hash] well description => control type
  # @param barcode [String] plate barcode
  # @return [Boolean] true if single controls, false if not (error rendered)
  def single_controls?(control_info, barcode)
    positive_count = control_info.values.count { |v| v == PCR_POSITIVE }
    negative_count = control_info.values.count { |v| v == PCR_NEGATIVE }
    if positive_count > 1 || negative_count > 1
      render_error(format(INCORRECT_CONTROLS, barcode:), :bad_request)
      return false
    end
    true
  end

  # Checks for presence of both positive and negative controls.
  # Renders error if either is missing.
  # @param control_info [Hash] well description => control type
  # @param barcode [String] plate barcode
  # @return [Boolean] true if both controls present, false if not
  def both_controls?(control_info, barcode)
    positive_count = control_info.values.count { |v| v == PCR_POSITIVE }
    negative_count = control_info.values.count { |v| v == PCR_NEGATIVE }

    if positive_count.zero? || negative_count.zero?
      render_error(format(MISSING_CONTROLS, barcode:), :bad_request)
      return false
    end
    true
  end
end
