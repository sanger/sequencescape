# frozen_string_literal: true

# Will construct tube racks with sample tubes filled with samples
class UatActions::GenerateTubeRacks < UatActions
  self.title = 'Generate tube rack'
  self.description = 'Generate tube racks in the selected study.'
  self.category = :generating_samples

  include UatActions::Shared::StudyHelper

  form_field :rack_count,
             :number_field,
             label: 'Rack Count',
             help: 'The number of racks to generate',
             options: {
               minimum: 1,
               maximum: 20
             }
  form_field :study_name,
             :select,
             label: 'Study',
             help: 'The study under which samples begin. List includes all active studies.',
             select_options: -> { Study.active.alphabetical.pluck(:name) }

  def self.default
    new(rack_count: 1, study_name: UatActions::StaticRecords.study.name)
  end

  def perform # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    purpose = Purpose.find_by(name: 'TR Stock 96')
    rack_count.to_i.times do |i|
      TubeRack
        .create!(size: 96, purpose: purpose)
        .tap do |rack|
          Barcode.create!(
            asset: rack,
            barcode: "AB#{Time.zone.now.hash.abs.to_s.slice(0, 8)}",
            format: 'fluidx_barcode'
          )
          construct_tubes(rack)
          report["rack_#{i}"] = rack.human_barcode
        end
    end
    true
  end

  private

  def construct_tubes(rack)
    rack_map.each do |i|
      tube = Tube::Purpose.standard_sample_tube.create!

      sample_name = "sample_#{rack.human_barcode}_#{i}"
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

      racked_tube = RackedTube.create!(tube_rack_id: rack.id, tube_id: tube.id, coordinate: i)
      rack.racked_tubes << racked_tube
    end
  end

  def rack_map
    map = []
    ('A'..'H').each { |letter| ('1'..'12').each { |number| map << (letter + number) } }
    map
  end
end
