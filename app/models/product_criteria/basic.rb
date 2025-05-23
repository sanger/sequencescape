# frozen_string_literal: true
# rubocop:todo Metrics/ClassLength
class ProductCriteria::Basic
  SUPPORTED_WELL_ATTRIBUTES = %i[
    gel_pass
    concentration
    rin
    current_volume
    pico_pass
    gender_markers
    measured_volume
    initial_volume
    molarity
    sequenom_count
  ].freeze
  SUPPORTED_SAMPLE = [:sanger_sample_id].freeze
  SUPPORTED_SAMPLE_METADATA = %i[gender sample_ebi_accession_number supplier_name phenotype sample_description].freeze
  EXTENDED_ATTRIBUTES = %i[
    total_micrograms
    conflicting_gender_markers
    sample_gender
    well_location
    plate_barcode
    concentration_from_normalization
  ].freeze

  PASSSED_STATE = 'passed'
  FAILED_STATE = 'failed'

  UnknownSpecification = Class.new(StandardError)

  attr_reader :passed, :params, :comment, :values
  alias passed? passed

  Comparison = Struct.new(:method, :message)

  METHOD_ALIAS = {
    greater_than: Comparison.new(:>, '%s too low'),
    less_than: Comparison.new(:<, '%s too high'),
    at_least: Comparison.new(:>=, '%s too low'),
    at_most: Comparison.new(:<=, '%s too high'),
    equals: Comparison.new(:==, '%s not suitable'),
    not_equal: Comparison.new(:'!=', '%s not suitable')
  }.freeze

  GENDER_MARKER_MAPS = { 'male' => 'M', 'female' => 'F' }.freeze

  class << self
    # Returns a list of possible criteria to either display or validate
    def available_criteria
      SUPPORTED_WELL_ATTRIBUTES + EXTENDED_ATTRIBUTES + SUPPORTED_SAMPLE_METADATA + SUPPORTED_SAMPLE
    end

    def headers(configuration)
      configuration.keys + [:comment]
    end
  end

  def initialize(params, well, target_wells = nil)
    @params = params
    @well_or_metric = well
    @comment = []
    @values = {}
    @target_wells = target_wells
    assess!
  end

  def total_micrograms
    return nil if current_volume.nil? || concentration.nil?

    (current_volume * concentration) / 1000.0
  end

  def conflicting_gender_markers
    (gender_markers || []).count { |marker| conflicting_marker?(marker) }
  end

  def metrics
    values.merge(comment: @comment.join(';'))
  end

  def well_location
    @well_or_metric.map_description
  end

  def plate_barcode
    @well_or_metric.labware.try(:human_barcode) || 'Unknown'
  end

  # We sort in Ruby here as we've loaded the wells in bulk. Performing this selection in
  # the database is actually more tricky than it sounds as your trying to load the latest
  # record from multiple different wells simultaneously.
  def most_recent_concentration_from_target_well_by_updating_date
    @target_wells.max_by { |w| w.well_attribute.updated_at }.get_concentration if @target_wells
  end

  def concentration_from_normalization
    most_recent_concentration_from_target_well_by_updating_date
  end

  SUPPORTED_SAMPLE.each { |attribute| delegate(attribute, to: :sample, allow_nil: true) }

  delegate(:sample_metadata, to: :sample, allow_nil: true)

  SUPPORTED_SAMPLE_METADATA.each { |attribute| delegate(attribute, to: :sample_metadata, allow_nil: true) }

  SUPPORTED_WELL_ATTRIBUTES.each { |attribute| delegate(attribute, to: :well_attribute, allow_nil: true) }

  # Return the sample gender, returns nil if it can't be determined
  # ie. mixed input, or not male/female
  def sample_gender
    markers =
      @well_or_metric.samples.map { |s| s.sample_metadata.gender && s.sample_metadata.gender.downcase.strip }.uniq
    return nil if markers.count > 1

    GENDER_MARKER_MAPS[markers.first]
  end

  def qc_decision
    passed? ? PASSSED_STATE : FAILED_STATE
  end

  def storage_location
    @well_or_metric.labware.try(:storage_location) || 'Unknown'
  end

  private

  def well_attribute
    @well_or_metric.well_attribute
  end

  def sample
    @well_or_metric.samples.first
  end

  def conflicting_marker?(marker)
    expected = sample_gender
    return false if expected.nil?
    return false unless known_marker?(marker)

    marker != expected
  end

  def known_marker?(marker)
    GENDER_MARKER_MAPS.value?(marker)
  end

  def invalid(attribute, message)
    @passed = false
    @comment << (message % attribute.to_s.humanize)
    @comment.uniq!
  end

  def assess! # rubocop:todo Metrics/MethodLength
    @passed = true
    params.each do |attribute, comparisons|
      value = fetch_attribute(attribute)
      values[attribute] = value

      if value.blank? && comparisons.present?
        invalid(attribute, '%s has not been recorded')
        next
      end

      comparisons.each do |comparison, target|
        value.send(method_for(comparison), target) || invalid(attribute, message_for(comparison))
      end
    end
  end

  # If @well_or_metric is a hash, then we are re-assessing the original criteria
  #
  # Note: This gives us the result at the time the criteria were
  # originally run, and doesn't take into account subsequent changes
  # in the well. This is useful if the metric has gone through multiple manual states.
  # This probably won't get callled for the basic class, but may be used for subclasses
  def fetch_attribute(attribute)
    @well_or_metric.is_a?(Hash) ? @well_or_metric[attribute] : send(attribute)
  end

  def method_for(comparison)
    comparison_for(comparison).method
  end

  def message_for(comparison)
    comparison_for(comparison).message
  end

  def comparison_for(comparison)
    METHOD_ALIAS.fetch(comparison) ||
      raise(UnknownSpecification, "#{comparison} isn't a recognised means of comparison.")
  end
end
# rubocop:enable Metrics/ClassLength
