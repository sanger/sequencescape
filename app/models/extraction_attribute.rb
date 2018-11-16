class ExtractionAttribute < ApplicationRecord
  include Uuid::Uuidable

  validates_presence_of :created_by

  # This is the target asset for which to update the state
  belongs_to :target, class_name: 'Asset', foreign_key: :target_id
  validates_presence_of :target

  validates_presence_of :attributes_update

  serialize :attributes_update

  before_save :update_performed

  class SampleTubeNotExists < StandardError
  end

  class WellNotExists < StandardError
  end

  class WellAlreadyHasSample < StandardError
  end

  def is_reracking?(well_info)
    well = well_info['resource']
    return false unless well

    (well.plate != target) || (well.map_description != well_info['location'])
  end

  def inject_resources(attr_well, attr_well_uuid_key, attr_well_resource_key)
    return unless attr_well

    if attr_well[attr_well_uuid_key]
      attr_well[attr_well_resource_key] = Uuid.find_by(external_id: attr_well[attr_well_uuid_key]).resource
    end
  end

  def attributes_update_with_resources
    attributes_update.each do |attr_well|
      inject_resources(attr_well, 'uuid', 'resource')
      inject_resources(attr_well, 'sample_tube_uuid', 'sample_tube_resource')
    end
    attributes_update
  end

  def update_performed
    ActiveRecord::Base.transaction do |_t|
      attributes_update_with_resources.each do |well_info|
        is_reracking?(well_info) ? rerack_well(well_info) : rack_well(well_info)
      end
      true
    end
  end

  def location_wells
    target.wells.includes(:map, :sample).index_by(&:map_description)
  end

  def disallow_wells_with_multiple_samples!(destination_well, samples)
    if (destination_well.samples.count > 0) && (destination_well.samples != samples)
      raise WellAlreadyHasSample
    end
  end

  def validate_well_for_racking_samples!(destination_well, samples)
    unless destination_well
      # TO RESEARCH:
      # If the well does not exist (because, for instance, it was reracked), we dont have
      # a well to rack. We should create a new well. For the moment, we'll fail in this situation
      raise WellNotExists
    end

    disallow_wells_with_multiple_samples!(destination_well, samples)
    samples.all? { |sample| !destination_well.samples.include?(sample) }
  end

  def rack_well(well_data)
    return unless well_data && well_data['sample_tube_uuid']
    unless well_data['sample_tube_resource']
      raise SampleTubeNotExists
    end

    sample_tube = well_data['sample_tube_resource']
    aliquots = sample_tube.aliquots.map(&:dup)
    samples = sample_tube.samples
    location = well_data['location']
    destination_well = location_wells[location]

    if validate_well_for_racking_samples!(destination_well, samples)
      destination_well.aliquots << aliquots
      AssetLink.create_edge(sample_tube, destination_well)
    end
  end

  def rerack_well(well_data)
    return unless well_data

    well = well_data['resource']
    previous_parent = well.parent
    actual_parent = target
    location = well_data['location']
    actual_well_in_same_position_at_rack = target.wells.located_at(location).first
    actual_map = target.maps.select { |m| m.description == location }.first
    raise WellNotExists if actual_map.nil?

    actual_well_in_same_position_at_rack&.update_attributes(plate: nil)
    well.update_attributes(plate: actual_parent, map: actual_map)
  end

  private :update_performed
end
