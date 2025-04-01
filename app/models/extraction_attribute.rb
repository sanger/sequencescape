# frozen_string_literal: true
class ExtractionAttribute < ApplicationRecord
  include Uuid::Uuidable

  validates :created_by, presence: true

  belongs_to :target, class_name: 'Labware'

  validates :target, presence: true

  validates :attributes_update, presence: true

  serialize :attributes_update, coder: YAML

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

  def find_resources(attr_well, attr_well_uuid_key)
    return unless attr_well

    Uuid.find_by(external_id: attr_well[attr_well_uuid_key]).resource if attr_well[attr_well_uuid_key]
  end

  def attributes_update_with_resources
    attributes_update.map do |attr_well|
      resources = {
        'resource' => find_resources(attr_well, 'uuid'),
        'sample_tube_resource' => find_resources(attr_well, 'sample_tube_uuid')
      }.compact
      attr_well.merge(resources)
    end
  end

  def update_performed
    ActiveRecord::Base.transaction do |_t|
      attributes_update_with_resources.each do |well_info|
        is_reracking?(well_info) ? rerack_well(well_info) : rack_well(well_info)
      end
    end
  end

  def location_wells
    target.wells.includes(:map, :samples, :aliquots).index_by(&:map_description)
  end

  def disallow_wells_with_multiple_samples!(destination_well, samples)
    raise WellAlreadyHasSample if (destination_well.samples.count > 0) && (destination_well.samples != samples)
  end

  def validate_well_for_racking_samples!(destination_well, samples)
    unless destination_well
      # TO RESEARCH:
      # If the well does not exist (because, for instance, it was reracked), we dont have
      # a well to rack. We should create a new well. For the moment, we'll fail in this situation
      raise WellNotExists
    end

    disallow_wells_with_multiple_samples!(destination_well, samples)
    samples.all? { |sample| destination_well.samples.exclude?(sample) }
  end

  def rack_well(well_data) # rubocop:todo Metrics/MethodLength
    return unless well_data && well_data['sample_tube_uuid']
    raise SampleTubeNotExists unless well_data['sample_tube_resource']

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

  def rerack_well(well_data) # rubocop:todo Metrics/AbcSize
    return unless well_data

    well = well_data['resource']

    actual_parent = target
    location = well_data['location']
    actual_well_in_same_position_at_rack = target.wells.located_at(location).first
    actual_map = target.maps.detect { |m| m.description == location }
    raise WellNotExists if actual_map.nil?

    actual_well_in_same_position_at_rack&.update!(plate: nil)

    # If an earlier well was moved into THIS wells previous location then
    # it will have been removed from the plate. HOWEVER, because this happens on
    # a DIFFERENT object, (as it gets found in a separate query) then this particular
    # instance of well has no way of knowing that this change has been made. This is
    # particularly problematic post-re-factor, as it results in the plate relationship
    # not getting flagged as dirty, and so not updating. As a result the update for the
    # earlier well takes precedence, and the location remains nil.
    # Container_associations didn't result in the same problem
    well.labware_id_will_change!

    well.update!(plate: actual_parent, map: actual_map)
  end

  private :update_performed
end
