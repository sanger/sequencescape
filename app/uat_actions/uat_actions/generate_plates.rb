# frozen_string_literal: true

# Will construct plates with well_count wells filled with samples
class UatActions::GeneratePlates < UatActions
  self.title = 'Generate plate'
  self.description = 'Generate plates in the selected study.'

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
             help: 'The number of occupied wells on each plate',
             options: {
               minimum: 1
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

  def self.default
    new(
      plate_count: 1,
      well_count: 96,
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

  def construct_wells(plate)
    wells(plate).each do |well|
      sample_name = "sample_#{plate.human_barcode}_#{well.map.description}"
      sample =
        Sample.new(
          name: sample_name,
          sanger_sample_id: sample_name,
          studies: [study],
          sample_metadata_attributes: {
            supplier_name: sample_name
          }
        )
      sample.save!(validate: false)
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
