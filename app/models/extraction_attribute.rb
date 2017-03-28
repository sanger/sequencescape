
class ExtractionAttribute < ActiveRecord::Base
  include Uuid::Uuidable

  validates_presence_of :created_by

  # This is the target asset for which to update the state
  belongs_to :target, class_name: 'Asset', foreign_key: :target_id
  validates_presence_of :target

  validates_presence_of :attributes_update

  serialize :attributes_update

  before_save :update_performed

  def update_performed
    location_wells = target.wells.includes(:map, :sample).index_by(&:map_description)
    attributes_update['wells'].each do |w|
      location = w['location']
      next unless w['sample_tube_uuid']
      sample_tube = Uuid.find_by(external_id: w['sample_tube_uuid']).resource
      aliquots = sample_tube.aliquots.map(&:dup)
      samples = sample_tube.samples
      destination_well = location_wells[location]

      unless destination_well.samples.include?(samples)
        destination_well.aliquots << aliquots
        AssetLink.create_edge(sample_tube, destination_well)
      end
    end
  end
  private :update_performed
end
