# frozen_string_literal: true

# This UAT action updates the state of all active requests matching the specified type
# in the labware of the specified barcode to the specified new state.
class UatActions::UpdateStateOfRequestsInLabware < UatActions
  self.title = 'Update State of Requests in Labware'
  self.description = 'Update the state of all active requests of the specified type in the labware.'
  self.category = :setup_and_test

  ERROR_LABWARE_DOES_NOT_EXIST = 'not found.'
  ERROR_REQUEST_TYPE_DOES_NOT_EXIST = 'not found.'
  ERROR_NO_ACTIVE_REQUESTS_FOUND = "No active requests of type '%s' found in labware '%s'."
  ERROR_FAILED_TO_UPDATE_REQUEST_STATE = 'Failed to update request state, error message: %s'

  # For this action we need a labware barcode, a request type name, and a new state.
  form_field :labware_barcode,
             :text_field,
             label: 'Labware Barcode',
             help: 'The barcode of the labware (e.g. SQPD-1234).'
  form_field :request_type_name,
             :text_field,
             label: 'Request Type Name',
             help: "The name of the request type (e.g. 'Ultima sequencing')."
  form_field :new_state,
             :text_field,
             label: 'New State',
             help: "The new state to set for the requests (e.g. 'started', 'completed')."

  attr_accessor :labware_barcode, :request_type_name, :new_state

  validates :labware_barcode, presence: true
  validates :labware, presence: { message: ERROR_LABWARE_DOES_NOT_EXIST }
  validates :request_type_name, presence: true
  validates :request_type, presence: { message: ERROR_REQUEST_TYPE_DOES_NOT_EXIST }
  validates :new_state, presence: true

  # Updates the requests and reports success in the report.
  # @return [Boolean] true if the UAT action was successful, false otherwise.
  def perform
    return false unless valid?

    requests = find_active_requests(labware, request_type)
    return false if requests.blank?

    update_requests(requests)
  end

  private

  def labware
    @labware ||= Labware.find_by_barcode(labware_barcode&.strip)
  end

  # Finds the request type by name.
  # @return [RequestType, nil] the request type if found, nil otherwise
  def request_type
    return @request_type if defined?(@request_type)

    @request_type = RequestType.find_by(name: request_type_name&.strip)
  end

  # Updates the state of the requests to the new state.
  # @param requests [Array<Request>] the requests to check for updating
  def update_requests(requests)
    modified_requests_count = safely_update_requests(requests)

    print_report(modified_requests_count)

    modified_requests_count != false
  end

  # Safely updates the state of the requests, handling any errors that may occur.
  # @param requests [Array<Request>] the requests to check for updating
  # @return [int, false] the number of requests updated, or false if an error occurred
  def safely_update_requests(requests)
    modified_requests_count = 0

    begin
      requests.each do |request|
        modified_requests_count += update_request_state(request)
      end
      modified_requests_count
    rescue StandardError => e
      handle_update_error(e)
      false
    end
  end

  # Updates the state of the request if it matches the specified request type.
  # @param request [Request] the request to update
  # @return [int] 1 if the request was updated, 0 otherwise
  def update_request_state(request)
    if request.request_type.name == request_type.name
      request.update!(state: new_state)
      1
    else
      0
    end
  end

  def handle_update_error(error)
    message = format(ERROR_FAILED_TO_UPDATE_REQUEST_STATE, error.message)
    errors.add(:request_type_name, message)
  end

  def find_active_requests(labware, _request_type)
    # Find both in-progress requests where this labware is the destination and requests where this labware is a source
    requests = labware.in_progress_requests + labware.requests_as_source

    # if we don't find any active requests, return an error
    if requests.empty?
      message = format(ERROR_NO_ACTIVE_REQUESTS_FOUND, request_type_name, labware_barcode)
      errors.add(:request_type_name, message)

      return nil
    end
    requests
  end

  # Adds the following information to the report:
  # - labware barcode of the labware processed
  # - request type name used to filter which requests were updated
  # - new state the requests were updated to
  # - number of requests updated to the new state
  # @param requests_count [int] the number of requests processed with updated states
  # @return [void]
  def print_report(requests_count)
    report['labware_barcode'] = labware_barcode
    report['request_type_name'] = request_type_name
    report['new_state'] = new_state
    report['updated_requests_count'] = requests_count
  end
end
