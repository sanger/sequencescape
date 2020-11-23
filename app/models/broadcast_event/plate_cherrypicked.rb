class BroadcastEvent::PlateCherrypicked < BroadcastEvent
  ROBOT_ROLE_TYPE = 'robot'
  SOURCE_PLATES_ROLE_TYPE = 'cherrypicking_source'
  SAMPLE_ROLE_TYPE = 'sample'
  DESTINATION_PLATE_ROLE_TYPE = 'cherrypicking_destination_labware'

  include BroadcastEvent::Helpers::ExternalSubjects

  set_event_type 'lh_beckman_cp_destination_created'

  seed_class Plate
  seed_subject :plate 

  validates :properties, presence: true
  validate :robot_present, :source_plates_present, :samples_present, :destination_present, if: :properties

  def initialize(args)
    super(args)
    _add_destination_plate
  end

  def robot_present
    check_property_role_type(:robot, ROBOT_ROLE_TYPE)
  end

  def source_plates_present
    check_property_role_type(:source_plates, SOURCE_PLATES_ROLE_TYPE)
  end

  def samples_present
    check_property_role_type(:samples, SAMPLE_ROLE_TYPE)
  end

  def destination_present
    check_property_role_type(:destination_plate, DESTINATION_PLATE_ROLE_TYPE)
  end

  def subjects_have_role_type?(role_type)
    properties[:subjects].any?{|sub| sub[:role_type] == role_type}
  end


  def destination_plate_subject
    {
      'uuid': seed.uuid,
      'role_type': DESTINATION_PLATE_ROLE_TYPE,
      'subject_type': 'plate',
      'friendly_name': seed.barcodes.first.human_barcode
    }
  end

  def check_property_role_type(property, role_type)
    unless subjects_have_role_type?(role_type)
      errors.add(property, 'not provided')
    end
  end

  private

  def _add_destination_plate
    return unless properties
    unless subjects_have_role_type?(DESTINATION_PLATE_ROLE_TYPE)
      properties[:subjects] = properties[:subjects].push(destination_plate_subject)
    end
  end
end