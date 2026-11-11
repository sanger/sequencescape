# frozen_string_literal: true

# Checks a work order's options against its submission template: the options the
# template's request types require and accept (their RequestType::Validators), the
# library type, and for the scRNA Core cDNA Prep template, its pooling strategy.
class ApiOperation::WorkOrder::Validation::SubmissionTemplateValidation
  BASE_POINTER = '/work_order/options/'

  # @param submission_template [SubmissionTemplate] the template of the work order's service
  # @param options [Hash] the work order's options
  # @param requested_receptacles [ApiOperation::WorkOrder::RequestedReceptacles] the work order's receptacles
  def initialize(submission_template, options = {}, requested_receptacles: nil)
    @submission_template = submission_template
    @options = options
    @requested_receptacles = requested_receptacles || ApiOperation::WorkOrder::RequestedReceptacles.new([])
  end

  # @return [Array<ApiOperation::Error>] the problems with the options: those of the request type
  #   validators, the library type and, for the scRNA Core cDNA Prep template, its pooling strategy
  def errors
    @errors ||= validate_options + validate_library_type + validate_scrna_core_cdna_prep_feasibility
  end

  # @return [Array<String>] the advice about the scRNA Core cDNA Prep work order, given when it has no errors
  def scrna_core_cdna_prep_feasibility_warnings
    scrna_feasibility&.warnings || []
  end

  private

  # @return [Array<ApiOperation::Error>] the problems with the pooling strategy of a scRNA Core
  #   cDNA Prep work order; empty for other templates
  def validate_scrna_core_cdna_prep_feasibility
    scrna_feasibility&.errors || []
  end

  def validate_options
    @submission_template.request_types.flat_map do |request_type|
      request_type.request_type_validators.flat_map { |validator| validate_option(request_type, validator) }
    end
  end

  def validate_option(request_type, validator)
    option = validator.request_option
    problem = option_problem(request_type, validator)

    problem ? [ApiOperation::Error.new("#{BASE_POINTER}#{option}", problem)] : []
  end

  def validate_library_type
    order_options.library_type
    []
  rescue ApiOperation::Error => e
    [e]
  end

  # @return [String, nil] what is wrong with the option; nil if it is fine
  def option_problem(request_type, validator)
    option = validator.request_option
    return invalid_value_detail(request_type, validator) if @options.key?(option)

    "Missing required option #{option}" unless optional?(validator)
  end

  def optional?(validator)
    validator.default.present? || validator.allow_blank?
  end

  # @return [String, nil] why the option's value isn't valid for the validator; nil if it is
  def invalid_value_detail(request_type, validator)
    value = cast_value(validator)
    return if validator.validate?(value) || (validator.allow_blank? && value.blank?)

    "#{value.inspect} is not valid for #{validator.request_option} on #{request_type.name}. " \
      "Valid options: #{validator.options.to_sentence}"
  end

  def cast_value(validator)
    value = @options[validator.request_option]
    validator.type_cast && value.present? ? value.public_send(validator.type_cast) : value
  end

  def order_options
    ApiOperation::WorkOrder::OrderOptions.new(@submission_template, @options, @requested_receptacles)
  end

  def scrna_feasibility
    unless @submission_template.name == Submission::ScrnaCoreCdnaPrepFeasibilityCalculator::SCRNA_CORE_CDNA_PREP_GEM_X_5P
      return
    end

    @scrna_feasibility ||= ApiOperation::WorkOrder::Validation::ScrnaCoreCdnaPrepFeasibility.new(
      @requested_receptacles, @options
    )
  end
end
