# frozen_string_literal: true

# Will generate concentrations for a given plate
class UatActions::GeneratePlateConcentrations < UatActions
  self.title = 'Generate Concentrations for a Plate'
  self.description = 'Generate a set of randomised concentrations for a plate.'

  form_field :plate_barcode,
             :text_field,
             label: 'Plate barcode',
             help: 'Enter the barcode of the plate for which you want to add concentrations. '\
                   'NB. only well containing aliquots will have concentrations set.'
  form_field :minimum_concentration,
             :number_field,
             label: 'Minimum concentration (ng/µl)',
             help: 'The minimum concentration the wells should have.',
             options: { minimum: 0 }
  form_field :maximum_concentration,
             :number_field,
             label: 'Maximum concentration (ng/µl)',
             help: 'The maximum concentration the wells should have.',
             options: { minimum: 0 }

  #
  # Returns a default copy of the UatAction which will be used to fill in the form, with values
  # for the min and max concentrations.
  #
  # @return [UatActions::GeneratePlateConcentrations] A default object for rendering a form
  def self.default
    new(minimum_concentration: 0, maximum_concentration: 1000)
  end

  validates :plate_barcode, presence: { message: 'could not be found' }
  validates :minimum_concentration, numericality: { only_integer: false }
  validates :maximum_concentration, numericality: { greater_than: 0, only_integer: false }
  validate :maximum_greater_than_minimum

  def perform
    qc_assay_results = construct_qc_assay
    report['number_well_concentrations_written'] = qc_assay_results[:num_wells_written]
    qc_assay_results[:qc_assay_success]
  end

  private

  def maximum_greater_than_minimum
    return true if max_conc > min_conc

    errors.add(:maximum_concentration, 'needs to be greater than minimum concentration')
    false
  end

  def labware
    @labware ||= Plate.find_by_barcode(plate_barcode.strip)
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
        key: 'concentration',
        value: create_random_concentration,
        units: 'ng/ul',
        assay_type: 'UAT_Testing',
        assay_version: 'Binning',
        qc_assay: qc_assay
      )
      num_wells_written += 1
    end
    qc_assay_success = qc_assay.save
    { qc_assay_success: qc_assay_success, num_wells_written: num_wells_written }
  end
end
