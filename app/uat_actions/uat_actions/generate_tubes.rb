# frozen_string_literal: true

# Will construct sample tubes filled with samples
class UatActions::GenerateTubes < UatActions
  self.title = 'Generate tubes'
  self.description = 'Generate sample tubes in the selected study.'

  form_field :tube_purpose_name,
             :select,
             label: 'Tube Purpose',
             help: 'Select the tube purpose to create',
             select_options: -> { Tube::Purpose.alphabetical.pluck(:name) }
  form_field :tube_count,
             :number_field,
             label: 'Tube Count',
             help: 'The number of tubes to generate',
             options: {
               minimum: 1,
               maximum: 96
             }
  form_field :study_name,
             :select,
             label: 'Study',
             help: 'The study under which samples are created. List includes all active studies.',
             select_options: -> { Study.active.alphabetical.pluck(:name) }

  def self.default
    new(tube_count: 1, study_name: UatActions::StaticRecords.study.name)
  end

  def perform
    tube_count.to_i.times do |i|
      tube = tube_purpose.create!

      sample_name = "sample_#{tube.human_barcode}_#{i}"
      tube.aliquots.create!(
        sample:
          Sample.create!(
            name: sample_name,
            studies: [study],
            sample_metadata_attributes: {
              supplier_name: sample_name
            }
          ),
        study: study
      )

      report["tube_#{i}"] = tube.human_barcode
    end
    true
  end

  private

  def study
    @study ||= Study.find_by!(name: study_name)
  end

  def tube_purpose
    Purpose.find_by!(name: tube_purpose_name)
  end
end