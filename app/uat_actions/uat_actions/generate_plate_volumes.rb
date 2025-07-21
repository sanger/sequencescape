# frozen_string_literal: true

# Will generate volumes for a given plate
class UatActions::GeneratePlateVolumes < UatActions
  self.title = 'Generate volumes for a plate'
  self.description = 'Generate a set of randomised volumes for a plate.'
  self.category = :quality_control

  form_field :plate_barcode,
             :text_field,
             label: 'Plate barcode',
             help:
               'Enter the barcode of the plate for which you want to add volumes. ' \
               'NB. only well containing aliquots will have volumes set.'
  form_field :minimum_volume,
             :number_field,
             label: 'Minimum Target Volume (µl)',
             help: 'The minimum volume the wells should have.',
             options: {
               minimum: 0
             }
  form_field :maximum_volume,
             :number_field,
             label: 'Maximum Target Volume (µl)',
             help: 'The maximum volume the wells should have.',
             options: {
               minimum: 0
             }

  #
  # Returns a default copy of the UatAction which will be used to fill in the form, with values
  # for the units, and min and max volumes.
  #
  # @return [UatActions::GeneratePlateVolumes] A default object for rendering a form
  def self.default
    new(minimum_volume: 0, maximum_volume: 100)
  end

  validates :plate_barcode, presence: { message: 'could not be found' }
  validates :minimum_volume, numericality: { only_integer: false }
  validates :maximum_volume, numericality: { greater_than: 0, only_integer: false }
  validate :maximum_greater_than_or_equal_to_minimum

  def perform
    qc_assay_results = construct_qc_assay
    report['number_well_volumes_written'] = qc_assay_results[:num_wells_written]
    qc_assay_results[:qc_assay_success]
  end

  private

  def maximum_greater_than_or_equal_to_minimum
    return true if max_vol >= min_vol

    errors.add(:maximum_volume, 'needs to be greater than or equal to minimum volume')
    false
  end

  def labware
    @labware ||= Plate.find_by_barcode(plate_barcode.strip)
  end

  def key
    @key ||= 'volume'
  end

  def min_vol
    @min_vol ||= minimum_volume.to_f
  end

  def max_vol
    @max_vol ||= maximum_volume.to_f
  end

  def create_random_volume
    value = (rand * (max_vol - min_vol)) + min_vol
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
        value: create_random_volume,
        units: 'µl',
        assay_type: 'UAT_Testing',
        assay_version: 'UAT_version',
        qc_assay: qc_assay
      )
      num_wells_written += 1
    end
    qc_assay_success = qc_assay.save
    { qc_assay_success:, num_wells_written: }
  end
end
