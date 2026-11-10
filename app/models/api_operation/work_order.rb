# frozen_string_literal: true

# Validates the work order in an operation's payload, resolves its submission
# template (SubmissionTemplateResolver), validates its requested labware
# (Validation::Validation), gives the requested plates their purpose
# (PlatePurposeResolver), validates its options against the template
# (Validation::SubmissionTemplateValidation) and creates its submission (SubmissionCreation).
# ApiOperation::CoordinatorJob runs it as the work_order task, after
# reception, and records the outcome.
class ApiOperation::WorkOrder
  # @param api_operation [ApiOperation] the operation to process
  def initialize(api_operation)
    @api_operation = api_operation
  end

  # @return [Array<Hash>] the errors, each with a :detail and a :pointer to
  #   the part of the payload; empty if the submission was created
  def call
    return validation_errors unless resolver.valid?

    template = find_template
    return template if template.is_a?(Array)

    errors = validate(template)
    return errors if errors.any?

    SubmissionCreation.new(@api_operation, template, requested_receptacles:).call
  end

  private

  # @return [SubmissionTemplate, Array<Hash>] the template, or the error if
  #   the service is unmapped or ambiguous, or its template is missing or deprecated
  def find_template
    resolver.submission_template
  rescue ApiOperation::Error => e
    [e.to_h]
  rescue StandardError => e
    [{ pointer: SubmissionTemplateResolver::POINTER, detail: e.message }]
  end

  # Validates the receptacles, gives the plates their purpose, then validates the options
  # against the template, which may depend on the purpose.
  # @return [Array<Hash>] the errors; empty if the work order is valid
  def validate(template)
    errors = Validation::Validation.new(@api_operation, requested_receptacles:).errors
    return errors.map(&:to_h) if errors.any?

    errors = assign_plate_purposes(template)
    return errors if errors.any?

    Validation::SubmissionTemplateValidation.new(
      template, work_order['options'] || {}, requested_receptacles:
    ).errors.map(&:to_h)
  end

  # The receptacles of the work order's requested labware, found once for all its steps.
  def requested_receptacles
    @requested_receptacles ||= RequestedReceptacles.new(work_order['requested_labware_identifiers'])
  end

  def work_order
    @work_order ||= JSON.parse(@api_operation.payload).fetch('work_order')
  end

  # Gives the validated requested plates the purpose mapped to the template, so the later
  # steps, which share the requested receptacles, see it.
  # @return [Array<Hash>] the error, if the mapping is at fault
  def assign_plate_purposes(template)
    PlatePurposeResolver.new(work_order, template, requested_receptacles:).assign!
    []
  rescue ApiOperation::Error => e
    [e.to_h]
  end

  def resolver
    @resolver ||= SubmissionTemplateResolver.new(@api_operation)
  end

  def validation_errors
    resolver.errors.map do |error|
      { pointer: "/work_order/#{error.attribute}", detail: error.full_message }
    end
  end
end
