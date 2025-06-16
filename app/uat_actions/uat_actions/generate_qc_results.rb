# frozen_string_literal: true

# Will generate qc results for a given plate
class UatActions::GenerateQcResults < UatActions
  self.title = 'Generate qc results for a plate or tube'
  self.description = 'Generate a set of randomised qc result values for a plate or tube.'
  self.category = :quality_control

  ATTRIBUTE_UNITS = {
    'molarity' => 'nM',
    'volume' => 'ul',
    'concentration' => 'ng/ul',
    'gender_markers' => 'bases',
    'loci_passed' => 'bases',
    'RIN' => 'RIN',
    'primer_panel' => 'panels',
    'loci_tested' => 'bases',
    'gel_pass' => 'status',
    'live_cell_count' => 'cells/ml',
    'viability' => '%'
  }.freeze

  form_field :labware_barcode,
             :text_field,
             label: 'Labware barcode',
             help:
               'Enter the barcode of the plate or tube for which you want to add qc results. ' \
               'NB. only wells/tubes containing aliquots will have qc results set.'
  form_field :measured_attribute,
             :select,
             label: 'Measured attribute',
             help: 'Select your choice of qc result to record',
             select_options: ATTRIBUTE_UNITS.keys,
             options: {
               include_blank: 'Select a type...'
             }

  form_field :units, :text_field, label: 'Units', help: 'Leave blank to select a sensible default for the attribute'

  form_field :minimum_value,
             :number_field,
             label: 'Minimum value',
             help: 'The minimum value the results should have.',
             options: {
               minimum: 0
             }
  form_field :maximum_value,
             :number_field,
             label: 'Maximum value',
             help: 'The maximum value the results should have.',
             options: {
               minimum: 0
             }

  #
  # Returns a default copy of the UatAction which will be used to fill in the form, with values
  # for the units, and min and max concentrations.
  #
  # @return [UatActions::GeneratePlateConcentrations] A default object for rendering a form
  def self.default
    new(measured_attribute: 'concentration', minimum_value: 0, maximum_value: 100)
  end

  validates :labware, presence: { message: 'could not be found' }
  validates :measured_attribute, presence: { message: 'needs a choice' }
  validates :minimum_value, numericality: { only_integer: false }
  validates :maximum_value, numericality: { greater_than: 0, only_integer: false }
  validate :maximum_greater_than_minimum

  def perform
    construct_qc_assay
  end

  private

  def maximum_greater_than_minimum
    return true if max_conc > min_conc

    errors.add(:maximum_value, 'needs to be greater than minimum value')
    false
  end

  def labware
    @labware ||= Labware.find_by_barcode(labware_barcode.strip)
  end

  def resolved_units
    units.presence || ATTRIBUTE_UNITS[measured_attribute]
  end

  def min_conc
    @min_conc ||= minimum_value.to_f
  end

  def max_conc
    @max_conc ||= maximum_value.to_f
  end

  def create_random_concentration
    value = (rand * (max_conc - min_conc)) + min_conc
    format('%.3f', value)
  end

  def construct_qc_assay
    qc_assay = QcAssay.new

    labware.receptacles.each do |receptacle|
      next if receptacle.aliquots.empty?

      qc_assay.qc_results.build(
        asset: receptacle,
        key: measured_attribute,
        value: create_random_concentration,
        units: resolved_units,
        assay_type: 'UAT_Testing',
        assay_version: 'Binning',
        qc_assay: qc_assay
      )
    end
    report['number_results_written'] = qc_assay.qc_results.length
    qc_assay.save
  end
end
