# frozen_string_literal: true

#
# Used to import legacy well attribute data into the qc results table. Should only need to
# be run once on the production database.
#
# Due to be run on or around 21/08/2018
#
# @author [jg16]
#
class ImportWellAttributes
  AttributeUnit = Struct.new(:well_attribute, :qc_result_key, :qc_result_units, :assay_type)

  SPINNER = ['🕛 ', '🕐 ', '🕑 ', '🕒 ', '🕓 ', '🕔 ', '🕕 ', '🕖 ', '🕗 ', '🕘 ', '🕙 ', '🕚 '].freeze

  # Handles the progress notifier, providing an activity spinner, stats about progress, a status line
  # and error logging.
  # rubocop:disable Rails/Output
  class Progress
    def initialize
      @spinner = SPINNER.cycle
      @complete = 0
      @errored_wells = []
      @new_qc_results = 0
      @skipped_qc_results = 0
      @max_length = 1
    end

    def progress(well, stage)
      next_string = "\r#{@spinner.next} Complete #{@complete} / Results created #{@new_qc_results} / Results Skipped #{@skipped_qc_results} / Errors #{@errored_wells.length}: Processing #{well.id} => #{stage}"
      @max_length = [@max_length, next_string.length].max
      print next_string.ljust(@max_length)
    end

    def complete(well)
      @complete += 1
      progress(well, 'Complete')
    end

    def skip(well, attribute)
      @skipped_qc_results += 1
      progress(well, "#{attribute} exists, skipped")
    end

    def processed(well, attribute)
      @new_qc_results += 1
      progress(well, "#{attribute} updated")
    end

    def error(well, message)
      puts "\rError: Well #{well.id}: #{message}".ljust(@max_length)
      @errored_wells << well.id
    end
  end
  # rubocop:enable Rails/Output

  ASSAY_VERSION = 'v0.0' # Pre-date and legacy import stuff
  DEFAULT_ASSAY_TYPE = 'Legacy Import'
  ATTRIBUTES = [
    AttributeUnit.new(:gel_pass, 'gel_pass', 'status', 'Gel'),
    AttributeUnit.new(:concentration, 'concentration', 'ng/ul', DEFAULT_ASSAY_TYPE),
    # Current volume may be calculated, and may not be based on a volume check.
    AttributeUnit.new(:current_volume, 'volume', 'ul', DEFAULT_ASSAY_TYPE),
    AttributeUnit.new(:sequenom_count, 'loci_passed', 'bases', :detect_snp_assay),
    AttributeUnit.new(:gender_markers, 'gender_markers', 'bases', :detect_gender_assay),
    AttributeUnit.new(:molarity, 'molarity', 'nM', DEFAULT_ASSAY_TYPE),
    AttributeUnit.new(:rin, 'RIN', 'RIN', DEFAULT_ASSAY_TYPE)
  ].freeze

  MEASURED_VOLUME = AttributeUnit.new(:measured_volume, 'volume', 'ul', "Volume Check #{DEFAULT_ASSAY_TYPE}")
  INITIAL_VOLUME = AttributeUnit.new(:initial_volume, 'volume', 'ul', "Volume Check #{DEFAULT_ASSAY_TYPE}")

  def self.measured_columns
    ATTRIBUTES.map(&:well_attribute)
  end

  def self.scope
    columns = measured_columns
    columns.reduce(WellAttribute.where.not(columns.pop => nil)) { |scope, column| scope.or(WellAttribute.where.not(column => nil)) }
           .includes(well: [:events, :qc_results, { plate: :purpose }])
  end

  def self.import
    progress = Progress.new
    scope.find_each do |wa|
      ImportWellAttributes.new(wa, progress).import
    end
  end

  attr_reader :well_attribute, :progress

  delegate :gel_pass, :concentration, :current_volume, :sequenom_count, :measured_volume, :initial_volume, :molarity, :rin, to: :well_attribute

  def initialize(well_attribute, progress)
    @well_attribute = well_attribute
    @progress = progress
  end

  def import
    progress.progress(well, 'Begin import')
    process_simple_attributes
    process_advanced_volumes
    progress.complete(well)
  end

  private

  # Gender markers are now stored as strings of M F and U, rather than an array
  # of 'M', 'F' and 'Unknown'
  def gender_markers
    Array(well_attribute.gender_markers).map(&:first)&.join('')
  end

  def well
    @well_attribute.well
  end

  def timestamp
    @well_attribute.updated_at
  end

  def sorted_events
    @sorted_events = well.events.sort_by(&:created_at).reverse
  end

  def qc_assay
    @qc_assay ||= QcAssay.new
  end

  # Simple attributes need no conversion or specialist logic
  def process_simple_attributes
    ATTRIBUTES.each do |attribute|
      value = send(attribute.well_attribute)
      next if value.blank?
      progress.progress(well, "Importing #{attribute.well_attribute}")
      if qc_result_exists?(attribute.qc_result_key)
        qc_result = qc_result_for(attribute.qc_result_key).value
        progress.error(well, "#{attribute.well_attribute} mismatching values: #{value} != #{qc_result}") if value.to_s != qc_result
        progress.skip(well, attribute.well_attribute)
      else
        import_attribute(attribute, value)
      end
    end
  end

  # Measured volume and initial volume may contain useful
  # historical data.
  def process_advanced_volumes
    # If we have a measured volume which is:
    # a) different to the current volume
    # b) unrecorded in the qc_results table
    # record it
    if update_measured_volume?
      created_at = (sorted_events.last&.created_at || timestamp) - 1.day # Ensure the value predates everything
      import_attribute(MEASURED_VOLUME, measured_volume, created_at)
    end
    # Do the same for the initial volume, also confirming it differs from
    # the measured_volume
    return unless update_initial_volume?
    created_at = (sorted_events.last&.created_at || timestamp) - 2.days # Ensure the value predates everything
    import_attribute(INITIAL_VOLUME, initial_volume, created_at)
  end

  def update_measured_volume?
    measured_volume &&
      (measured_volume != current_volume) &&
      !volume_results.include?(measured_volume.to_s)
  end

  def update_initial_volume?
    initial_volume &&
      (initial_volume != current_volume) &&
      (initial_volume != measured_volume) &&
      !volume_results.include?(initial_volume.to_s)
  end

  def volume_results
    @volume_results ||= well.qc_results.select { |result| result.key.casecmp?('volume') }.map(&:value)
  end

  def import_attribute(attribute, value, created_at = timestamp)
    key = attribute.qc_result_key
    units = attribute.qc_result_units
    assay_type = assay_type_for(attribute)
    qcr = QcResult.new(asset: well, qc_assay: qc_assay, key: key, value: value, units: units, assay_type: assay_type, assay_version: ASSAY_VERSION, created_at: created_at, suppress_updates: true)
    if qcr.save
      progress.processed(well, attribute.well_attribute)
    else
      progress.error(well, "#{attribute.well_attribute} #{qcr.errors.full_messages.join('; ')}")
    end
  end

  def assay_type_for(attribute)
    return attribute.assay_type if attribute.assay_type.is_a?(String)
    send(attribute.assay_type)
  end

  def detect_snp_assay
    sorted_events.detect { |event| event.family == 'update_sequenom_count' }&.content || DEFAULT_ASSAY_TYPE
  end

  def detect_gender_assay
    sorted_events.detect { |event| event.family == 'update_gender_markers' }&.content || DEFAULT_ASSAY_TYPE
  end

  def qc_result_for(key)
    well.qc_results.detect { |result| result.key.casecmp? key }
  end

  def qc_result_exists?(key)
    qc_result_for(key).present?
  end
end
