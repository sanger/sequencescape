# frozen_string_literal: true

# The request options of a work order's order: the options parsed from the work
# order's JSON, merged with the options calculated for its template. The
# calculated ones aren't in the work order and need no user input; this is what
# BulkSubmission#calculated_request_options_by_template_name does for a
# spreadsheet. Currently the scRNA Core cDNA Prep template has an
# `allowance_band` option.
class ApiOperation::WorkOrder::OrderOptions
  # Options of the work order that are attributes of the order or submission rather than request options
  NON_REQUEST_OPTIONS = %w[number_of_lanes priority comments pre_capture_group].freeze

  LIBRARY_TYPE_POINTER = '/work_order/options/library_type'

  # @param template [SubmissionTemplate] the template of the work order's service
  # @param options [Hash] the work order's options, as parsed from its JSON
  # @param requested_receptacles [ApiOperation::WorkOrder::RequestedReceptacles] the work order's receptacles
  def initialize(template, options, requested_receptacles)
    @template = template
    @options = options || {}
    @requested_receptacles = requested_receptacles
  end

  # @return [Hash] the work order's options with the calculated ones; calculated
  #   values replace those of the same name
  def all_options
    @options.merge(calculated_options)
  end

  # @return [Hash] the options the requests are made with: the order's options without those that
  #   are attributes of the order or submission
  def request_options
    options = { read_length: all_options['read_length'], multiplier: {} }
      .merge(all_options.except('read_length', *NON_REQUEST_OPTIONS))
    options['library_type'] = library_type if options.key?('library_type')
    options.compact
  end

  # @return [String, nil] the library type in its own case, which NPG needs; nil if not given
  # @raise [ApiOperation::Error] if the library type isn't one Sequencescape has
  def library_type
    lib_type = @options['library_type']
    return if lib_type.blank?

    LibraryType.find_by(name: lib_type)&.name ||
      raise(ApiOperation::Error.new(LIBRARY_TYPE_POINTER, "Sequencescape cannot find library type #{lib_type.inspect}"))
  end

  # @return [String, nil] the comments of the order
  def comments
    all_options['comments']
  end

  # @return [Integer, nil] the pre-capture group of the order
  def pre_capture_group
    all_options['pre_capture_group']
  end

  # @return [Integer] the number of lanes; 1 if not given
  def number_of_lanes
    all_options.fetch('number_of_lanes', 1).to_i
  end

  # @return [Integer] the submission's priority, from its name or number; 0 if not given
  def priority
    priority = all_options['priority']
    Submission::Priorities.priorities.index(priority) || priority.to_i
  end

  # @return [Hash] e.g. { 'allowance_band' => '2 pool attempts, 2 counts' }; empty if the
  #   template has none
  def calculated_options
    return {} unless @template.name == Submission::ScrnaCoreCdnaPrepFeasibilityCalculator::SCRNA_CORE_CDNA_PREP_GEM_X_5P

    { 'allowance_band' => scrna_feasibility.allowance_band }
  end

  private

  def scrna_feasibility
    ApiOperation::WorkOrder::Validation::ScrnaCoreCdnaPrepFeasibility.new(@requested_receptacles, @options)
  end
end
