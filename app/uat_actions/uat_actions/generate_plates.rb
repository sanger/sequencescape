# frozen_string_literal: true

# Will construct plates with well_count wells filled with samples
class UatActions::GeneratePlates < UatActions
  self.title = 'Generate plate'
  self.description = 'Generate plates in the selected study.'
  self.category = :generating_samples

  form_field :plate_purpose_name,
             :select,
             label: 'Plate Purpose',
             help: 'Select the plate purpose to create',
             select_options: -> { PlatePurpose.alphabetical.pluck(:name) }
  form_field :plate_count,
             :number_field,
             label: 'Plate Count',
             help: 'The number of plates to generate',
             options: {
               minimum: 1,
               maximum: 20
             }
  form_field :well_count,
             :number_field,
             label: 'Well Count',
             help: 'The number of occupied wells on each plate (locations will be randomised if less than full)',
             options: {
               minimum: 1
             }
  form_field :number_of_samples_in_each_well,
             :number_field,
             label: 'Number of samples in each well',
             help: 'The number of samples to create in each well. Default is 1. Max 10.',
             options: {
               minimum: 1,
               maximum: 10
             }
  form_field :study_name,
             :select,
             label: 'Study',
             help: 'The study under which samples begin. List includes all active studies.',
             select_options: -> { Study.active.alphabetical.pluck(:name) }
  form_field :well_layout,
             :select,
             label: 'Well layout',
             help: 'The order in which wells are laid out. Affects where empty wells are located.',
             select_options: %w[Column Row Random]

  validate :well_count_smaller_than_plate_size
  validates :number_of_samples_in_each_well, numericality: { greater_than: 0, only_integer: true, allow_blank: false }

  def self.default
    new(
      plate_count: 1,
      well_count: 96,
      number_of_samples_in_each_well: 1,
      study_name: UatActions::StaticRecords.study.name,
      plate_purpose_name: PlatePurpose.stock_plate_purpose.name,
      well_layout: 'Column'
    )
  end

  def perform
    plate_count.to_i.times do |i|
      plate_purpose.create!.tap do |plate|
        construct_wells(plate)
        report["plate_#{i}"] = plate.human_barcode
        yield plate if block_given?
      end
    end
    true
  end

  private

  def well_count_smaller_than_plate_size
    return true if well_count.to_i <= plate_purpose.size

    errors.add(:well_count, "is larger than the size of a #{plate_purpose.name} (plate_purpose.size)")
    false
  end

  # Ensures number of samples per occupied well is at least 1
  def num_samples_per_well
    @num_samples_per_well ||=
      if number_of_samples_in_each_well.present? && number_of_samples_in_each_well.to_i.positive?
        number_of_samples_in_each_well.to_i
      else
        1
      end
  end

  # Constructs wells for the given plate.
  # For each well in the plate, it creates the specified number of samples using the `create_sample` method.
  # @param plate [Plate] the plate for which to construct wells
  def construct_wells(plate)
    wells(plate).each do |well|
      num_samples_per_well.times { |sample_index| create_sample(plate, well, sample_index + 1) }
    end
  end

  # Creates a new sample with a unique name based on the plate, well, and sample index.
  # The sample is built using the `build_sample` method and saved using the `save_sample` method.
  # If the sample fails to save due to an ActiveRecord::RecordInvalid error, the error message is
  # added to the base errors.
  # @param plate [Plate] the plate associated with the sample
  # @param well [Well] the well associated with the sample
  # @param sample_index [Integer] the index of the sample
  # @raise [ActiveRecord::RecordInvalid] if the sample fails to save
  def create_sample(plate, well, sample_index)
    sample_name = "sample_#{sample_index}_#{plate.human_barcode}_#{well.map.description}"
    sample = build_sample(sample_name, plate)
    save_sample(sample, well, sample_index)
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, "Failed to create sample: #{e.message}")
  end

  # Builds a new Sample object with the given name and associated plate.
  # The sample's metadata attributes are also set, including the supplier name, cohort, and sample description.
  # @param sample_name [String] the name of the sample, also used as the sanger_sample_id and supplier_name
  # @param plate [Plate] the plate associated with the sample, its human_barcode is used in the cohort and
  # sample_description
  # @return [Sample] the newly built Sample object
  def build_sample(sample_name, plate)
    Sample.new(
      name: sample_name,
      sanger_sample_id: sample_name,
      studies: [study],
      sample_metadata_attributes: {
        supplier_name: sample_name,
        cohort: "Cohort#{plate.human_barcode}",
        sample_description: "SD-#{plate.human_barcode}",
        sample_common_name: 'human'
      }
    )
  end

  # Saves the given sample and creates an aliquot in the specified well.
  # If there are multiple samples in each well, the aliquot is created with a tag depth.
  # @param sample [Sample] the sample to be saved
  # @param well [Well] the well where the aliquot will be created
  # @param sample_index [Integer] the index of the sample in the well, used as tag depth
  # if there are multiple samples per well
  def save_sample(sample, well, sample_index)
    sample.save!(validate: false)

    if num_samples_per_well > 1
      well.aliquots.create!(sample: sample, study: study, tag_depth: sample_index)
    else
      well.aliquots.create!(sample: sample, study: study)
    end
  end

  def wells(plate) # rubocop:todo Metrics/AbcSize
    case well_layout
    when 'Column'
      plate.wells.in_column_major_order.includes(:map).limit(well_count)
    when 'Row'
      plate.wells.in_row_major_order.includes(:map).limit(well_count)
    when 'Random'
      plate.wells.includes(:map).all.sample(well_count.to_i)
    else
      raise StandardError, "Unknown layout: #{well_layout}"
    end
  end

  def study
    @study ||= Study.find_by!(name: study_name)
  end

  def plate_purpose
    Purpose.find_by!(name: plate_purpose_name)
  end
end
