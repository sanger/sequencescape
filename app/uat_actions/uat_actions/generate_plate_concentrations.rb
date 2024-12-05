# frozen_string_literal: true

# Will generate concentrations for a given plate
class UatActions::GeneratePlateConcentrations < UatActions
  self.title = 'Generate concentrations for a plate'
  self.description = 'Generate a set of randomised concentrations for a plate.'
  self.category = :quality_control

  form_field :plate_barcode,
             :text_field,
             label: 'Plate barcode',
             help:
               'Enter the barcode of the plate for which you want to add concentrations. ' \
                 'NB. only well containing aliquots will have concentrations set.'
  form_field :concentration_units,
             :select,
             label: 'Concentration type (ng/µl or nM)',
             help: 'Select your choice of creating a concentration in ng/µl or as a molarity',
             select_options: %w[ng/ul nM],
             options: {
               include_blank: 'Select a type...'
             }
  form_field :minimum_concentration,
             :number_field,
             label: 'Minimum concentration',
             help: 'The minimum concentration the wells should have.',
             options: {
               minimum: 0
             }
  form_field :maximum_concentration,
             :number_field,
             label: 'Maximum concentration',
             help: 'The maximum concentration the wells should have.',
             options: {
               minimum: 0
             }

  #
  # Returns a default copy of the UatAction which will be used to fill in the form, with values
  # for the units, and min and max concentrations.
  #
  # @return [UatActions::GeneratePlateConcentrations] A default object for rendering a form
  def self.default
    new(concentration_units: 'ng/ul', minimum_concentration: 0, maximum_concentration: 100)
  end

  validates :plate_barcode, presence: { message: 'could not be found' }
  validates :concentration_units, presence: { message: 'needs a choice' }
  validates :minimum_concentration, numericality: { only_integer: false }
  validates :maximum_concentration, numericality: { greater_than: 0, only_integer: false }
  validate :maximum_greater_than_or_equal_to_minimum

  def perform
    qc_assay_results = construct_qc_assay
    report['number_well_concentrations_written'] = qc_assay_results[:num_wells_written]
    qc_assay_results[:qc_assay_success]
  end

  private

  def maximum_greater_than_or_equal_to_minimum
    return true if max_conc >= min_conc

    errors.add(:maximum_concentration, 'needs to be greater than or equal to minimum concentration')
    false
  end

  def labware
    @labware ||= Plate.find_by_barcode(plate_barcode.strip)
  end

  def conc_units
    @conc_units ||= concentration_units
  end

  def key
    @key ||= decide_key
  end

  def decide_key
    conc_units == 'nM' ? 'molarity' : 'concentration'
  end

  def min_conc
    @min_conc ||= minimum_concentration.to_f
  end

  def max_conc
    @max_conc ||= maximum_concentration.to_f
  end

  def create_random_concentration
    value = (rand * (max_conc - min_conc)) + min_conc
    format('%.3f', value)
  end

  def construct_qc_assay
    qc_assay = QcAssay.new
    num_wells_written = 0

    labware.wells.each do |well|
      next if well.aliquots.empty?

      QcResult.create!(
        asset: well,
        key: key,
        value: create_random_concentration,
        units: conc_units,
        assay_type: 'UAT_Testing',
        assay_version: 'Binning',
        qc_assay: qc_assay
      )
      num_wells_written += 1
    end
    qc_assay_success = qc_assay.save
    { qc_assay_success:, num_wells_written: }
  end
end
