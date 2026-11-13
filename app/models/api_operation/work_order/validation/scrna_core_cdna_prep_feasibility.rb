# frozen_string_literal: true

# Checks that the pooling strategy of a scRNA Core cDNA Prep work order is
# feasible, so it can be adjusted at the submission stage rather than at the
# pooling stage. It is the work order counterpart of
# Submission::ScrnaCoreCdnaPrepFeasibilityValidator, which reads the same rules
# from a bulk submission spreadsheet. A work order is a single submission of one
# study and project, so there is a single group of requested receptacles, and
# its settings are the work order's options:
# - number_of_pools
# - cells_per_chip_well
#
# Errors are reported when:
# - the total number of samples is outside the configured range
# - the number of pools is outside the configured range
# - the smallest or biggest pool would have too few or too many samples
# - a donor has more samples than there are pools (donor clash)
#
# A warning, only given if there are no errors, is reported when there is not
# enough material for the "full allowance" (2 full runs on the chip).
#
# The messages are the strings in the locale file.
class ApiOperation::WorkOrder::Validation::ScrnaCoreCdnaPrepFeasibility # rubocop:todo Metrics/ClassLength
  include Submission::ScrnaCoreCdnaPrepFeasibilityCalculator

  I18N_SCOPE = 'submissions.scrna_core_cdna_prep_feasibility_validator'
  OPTIONS_POINTER = '/work_order/options/'
  IDENTIFIERS_POINTER = '/work_order/requested_labware_identifiers'
  OPTION_POOLS = 'number_of_pools'
  OPTION_CELLS = 'cells_per_chip_well'
  ALLOWANCE_BAND_RUNS_AND_COUNTS = [
    [:two_pools_two_counts, 2, 2],
    [:two_pools_one_count, 2, 1],
    [:one_pool_two_counts, 1, 2],
    [:one_pool_one_count, 1, 1]
  ].freeze

  # @param requested_receptacles [ApiOperation::WorkOrder::RequestedReceptacles] the work order's receptacles
  # @param options [Hash] the work order's options
  def initialize(requested_receptacles, options)
    @requested_receptacles = requested_receptacles
    @options = options || {}
  end

  # @return [Array<ApiOperation::Error>] the problems found
  def errors
    @errors ||= find_errors
  end

  # @return [Array<String>] the advice, only given when there are no errors
  def warnings
    errors.empty? ? full_allowance_warnings : []
  end

  # The allowance band of the work order, as BulkSubmission's allowance_band request option:
  # the first band, from the biggest, that the final resuspension volume covers.
  # @return [String, nil] e.g. '2 pool attempts, 2 counts'; nil if no band is covered
  def allowance_band
    final_resuspension_volume = calculate_resuspension_volume(number_of_samples_in_smallest_pool)
    band, = ALLOWANCE_BAND_RUNS_AND_COUNTS.find do |_band, runs, counts|
      final_resuspension_volume >= calculate_volume_needed(number_of_cells_per_chip_well, runs, counts)
    end
    ALLOWANCE_BANDS[band]
  end

  private

  def find_errors
    option_errors = option_presence_errors
    return option_errors if option_errors.any?

    [
      total_number_of_samples_error,
      total_number_of_pools_error,
      *pool_size_errors,
      donor_clash_error
    ].compact
  end

  def option_presence_errors
    [OPTION_POOLS, OPTION_CELLS].filter_map do |option|
      next if @options[option].to_i.positive?

      ApiOperation::Error.new("#{OPTIONS_POINTER}#{option}", "#{option} must be a number greater than zero")
    end
  end

  def number_of_pools
    @options[OPTION_POOLS].to_i
  end

  def number_of_cells_per_chip_well
    @options[OPTION_CELLS].to_i
  end

  # Each identifier that names a receptacle, with it, in the order requested.
  def requested
    @requested_receptacles.identified_receptacles
  end

  def number_of_samples
    @number_of_samples ||= requested.sum { |_identifier, receptacle| receptacle.samples.count }
  end

  def total_number_of_samples_error
    min = scrna_config[:cdna_prep_minimum_total_number_of_samples]
    max = scrna_config[:cdna_prep_maximum_total_number_of_samples]
    return if number_of_samples.between?(min, max)

    build_error(IDENTIFIERS_POINTER, 'errors.total_number_of_samples', min: min, max: max, count: number_of_samples)
  end

  def total_number_of_pools_error
    min = scrna_config[:cdna_prep_minimum_total_number_of_pools]
    max = scrna_config[:cdna_prep_maximum_total_number_of_pools]
    return if number_of_pools.between?(min, max)

    build_error("#{OPTIONS_POINTER}#{OPTION_POOLS}", 'errors.total_number_of_pools', min: min, max: max,
                                                                                     count: number_of_pools)
  end

  def pool_size_errors
    min = scrna_config[:cdna_prep_minimum_number_of_samples_per_pool]
    max = scrna_config[:cdna_prep_maximum_number_of_samples_per_pool]
    calculate_pool_size_types(number_of_samples, number_of_pools).filter_map do |size_type, pool_size|
      next if pool_size.between?(min, max)

      build_error("#{OPTIONS_POINTER}#{OPTION_POOLS}", 'errors.number_of_pools_by_samples',
                  min: min, max: max, count: pool_size, size_type: size_type, **names)
    end
  end

  # The smallest pool size is the quotient of samples over pools; the biggest
  # is one more if there is a remainder, and is left out if it's the same.
  def calculate_pool_size_types(number_of_samples, number_of_pools)
    quotient, remainder = number_of_samples.divmod(number_of_pools)
    size_types = { 'smallest' => quotient }
    size_types['biggest'] = quotient + 1 if remainder.positive?
    size_types
  end

  # Samples of one donor can't share a pool, so there can't be more of them than pools.
  def donor_clash_error
    _donor_id, biggest_group = requested.group_by { |_identifier, receptacle| donor_id(receptacle) }
      .max_by { |_donor_id, group| group.size }
    return if biggest_group.nil? || biggest_group.size <= number_of_pools

    build_error(IDENTIFIERS_POINTER, 'errors.number_of_pools_by_donors',
                count: biggest_group.size, number_of_pools: number_of_pools,
                barcodes_or_well_locations: biggest_group.map(&:first).join(', '), **names)
  end

  def donor_id(receptacle)
    receptacle.aliquots.first&.sample&.sample_metadata.try(:donor_id)
  end

  def number_of_samples_in_smallest_pool
    calculate_pool_size_types(number_of_samples, number_of_pools)['smallest']
  end

  def full_allowance_warnings
    final_resuspension_volume = calculate_resuspension_volume(number_of_samples_in_smallest_pool)
    full_allowance = calculate_volume_needed(number_of_cells_per_chip_well, 2, 2)
    return [] if final_resuspension_volume >= full_allowance

    [
      I18n.t('warnings.full_allowance',
             number_of_samples_in_smallest_pool: number_of_samples_in_smallest_pool,
             final_resuspension_volume: final_resuspension_volume.round(1),
             full_allowance: full_allowance.round(1),
             **names, scope: I18N_SCOPE)
    ]
  end

  # The study and project of the requested samples, for the messages.
  def names
    aliquots = requested.flat_map { |_identifier, receptacle| receptacle.aliquots.to_a }
    {
      study_name: aliquots.filter_map { |aliquot| aliquot.study&.name }.uniq.join(', '),
      project_name: aliquots.filter_map { |aliquot| aliquot.project&.name }.uniq.join(', ')
    }
  end

  def build_error(pointer, key, **)
    ApiOperation::Error.new(pointer, I18n.t(key, **, scope: I18N_SCOPE))
  end

  def scrna_config
    Rails.application.config.scrna_config
  end
end
