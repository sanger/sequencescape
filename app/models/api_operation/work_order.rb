# frozen_string_literal: true

# The work_order task of an ApiOperation, run by ApiOperation::CoordinatorJob
# after reception. For the work order in the operation's payload it:
# Services configured as N/A (e.g. Long Read Amplicon- PacBio) need nothing from
# Sequencescape: the task completes without creating a submission.
#
# 1. resolves the submission template (SubmissionTemplateResolver);
# 2. finds or creates the project of its cost code (SapioProjectResolver);
# 3. validates it: the required fields and requested labware (Validation::Validation),
#    then the plates' purpose is assigned (PlatePurposeResolver), then its options
#    against the template (Validation::SubmissionTemplateValidation);
# 4. creates its submission (SubmissionCreation), which is built by a delayed job
#    (SubmissionBuilderJob) that creates the requests of its orders.
#
# It returns the errors found, which the coordinator job stores in the operation's
# error_details and marks the task failed; with none, the task is completed.
class ApiOperation::WorkOrder < ApiOperation::Task
  # @return [Array<Hash>] the errors, each with a :detail and a :pointer to
  #   the part of the payload; empty if the submission was created
  def call
    return validation_errors unless resolver.valid?
    return [] if resolver.not_applicable?

    template = find_template
    return template if template.is_a?(Array)

    project = find_project
    return project if project.is_a?(Array)

    errors = validate(template)
    return errors if errors.any?

    SubmissionCreation.new(api_operation, template, project:, requested_receptacles:).call
  end

  private

  # @return [SubmissionTemplate, Array<Hash>] the template, or the error if
  #   the service is unmapped or ambiguous, or its template is missing or deprecated.
  #   Any other error is unexpected and left to the coordinator.
  def find_template
    resolver.submission_template
  rescue ApiOperation::Error => e
    [e.to_h]
  end

  # @return [Project, Array<Hash>] the project of the work order's cost code, or the error
  #   if it cannot be found or created
  def find_project
    cost_code = work_order['cost_code'].to_s.strip
    return [{ pointer: '/work_order/cost_code', detail: 'cost_code is required' }] if cost_code.empty?

    SapioProjectResolver.new(cost_code).find_or_create
  rescue ActiveRecord::RecordInvalid => e
    [{ pointer: '/work_order/cost_code', detail: e.message }]
  end

  # Validates the receptacles, gives the plates their purpose, then validates the options
  # against the template, which may depend on the purpose.
  # @return [Array<Hash>] the errors; empty if the work order is valid
  def validate(template)
    errors = Validation::Validation.new(api_operation, requested_receptacles:).errors
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
    @work_order ||= JSON.parse(api_operation.payload).fetch('work_order')
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
    @resolver ||= SubmissionTemplateResolver.new(api_operation)
  end

  def validation_errors
    resolver.errors.map do |error|
      { pointer: "/work_order/#{error.attribute}", detail: error.full_message }
    end
  end
end
