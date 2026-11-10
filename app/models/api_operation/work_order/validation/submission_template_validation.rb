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

  # @return [Array<ApiOperation::Error>] the problems with the pooling strategy of a scRNA Core
  #   cDNA Prep work order; empty for other templates
  def validate_scrna_core_cdna_prep_feasibility
    scrna_feasibility&.errors || []
  end

  # @return [Array<String>] the advice about the scRNA Core cDNA Prep work order, given when it has no errors
  def scrna_core_cdna_prep_feasibility_warnings
    scrna_feasibility&.warnings || []
  end

  def validate_options
    @submission_template.request_types.flat_map do |request_type|
      request_type.request_type_validators.flat_map { |validator| validate_option(request_type, validator) }
    end
  end

  def validate_option(request_type, validator)
    option = validator.request_option
    pointer = "#{BASE_POINTER}#{option}"

    unless @options.key?(option)
      return [] if validator.default.present? || validator.allow_blank?

      return [ApiOperation::Error.new(pointer, "Missing required option #{option}")]
    end

    value = @options[option]
    value = value.public_send(validator.type_cast) if validator.type_cast && value.present?
    return [] if validator.validate?(value) || (validator.allow_blank? && value.blank?)

    [ApiOperation::Error.new(pointer,
                             "#{value.inspect} is not valid for #{option} on #{request_type.name}. " \
                             "Valid options: #{validator.options.to_sentence}")]
  end

  def validate_library_type
    library_type = @options['library_type']
    return [] unless library_type.present?
    return [] if LibraryType.exists?(name: library_type)

    [ApiOperation::Error.new("#{BASE_POINTER}library_type",
                             "Sequencescape cannot find library type #{library_type.inspect}")]
  end

  private

  def scrna_feasibility
    unless @submission_template.name == Submission::ScrnaCoreCdnaPrepFeasibilityCalculator::SCRNA_CORE_CDNA_PREP_GEM_X_5P
      return
    end

    @scrna_feasibility ||= ApiOperation::WorkOrder::Validation::ScrnaCoreCdnaPrepFeasibility.new(
      @requested_receptacles, @options
    )
  end
end
