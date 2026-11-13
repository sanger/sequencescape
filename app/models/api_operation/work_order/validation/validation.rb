# frozen_string_literal: true

# Checks that a work order has its required fields, and that the labware it
# requests exists and has contents, and each requested receptacle has one study.
class ApiOperation::WorkOrder::Validation::Validation
  POINTER = '/work_order'

  # @param api_operation [ApiOperation] the operation whose work order to check
  # @param requested_receptacles [ApiOperation::WorkOrder::RequestedReceptacles, nil] the
  #   work order's requested receptacles, found from its identifiers if not given
  def initialize(api_operation, requested_receptacles: nil)
    @work_order = JSON.parse(api_operation.payload).fetch('work_order')
    @requested_receptacles = requested_receptacles ||
      ApiOperation::WorkOrder::RequestedReceptacles.new(@work_order['requested_labware_identifiers'])
  end

  # @return [Array<ApiOperation::Error>] the problems; labware is only checked
  #   once the required fields are present
  def errors
    @errors ||= required_field_errors.presence || labware_errors
  end

  private

  # Read from the configured schema, so this follows its required properties.
  # An empty value, such as an empty options hash, is only rejected for text.
  def required_fields
    ApiOperation::SchemaCheck.new(nil).required_properties('work_order')
  end

  def required_field_errors
    required_fields.filter_map do |field|
      value = @work_order[field]
      next unless value.nil? || (value.respond_to?(:strip) && value.strip.empty?)

      ApiOperation::Error.new("#{POINTER}/#{field}", "#{field} is required")
    end
  end

  def labware_errors
    @requested_receptacles.errors.presence || @requested_receptacles.study_errors
  end
end
