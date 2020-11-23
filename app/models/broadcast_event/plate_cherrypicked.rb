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

  # It adds the destination plate subject from the plate seed if the destination plate 
  # subject has not been provided on initialization
  def initialize(args)
    super(args)
    _add_destination_plate
  end

  def robot_present
    check_subject_role_type(:robot, ROBOT_ROLE_TYPE)
  end

  def source_plates_present
    check_subject_role_type(:source_plates, SOURCE_PLATES_ROLE_TYPE)
  end

  def samples_present
    check_subject_role_type(:samples, SAMPLE_ROLE_TYPE)
  end

  def destination_present
    check_subject_role_type(:destination_plate, DESTINATION_PLATE_ROLE_TYPE)
  end

  # Default destination plate subject definition using the seeding plate. It won't be used
  # if another subject is provided on initialization
  def default_destination_plate_subject
    {
      'uuid': seed.uuid,
      'role_type': DESTINATION_PLATE_ROLE_TYPE,
      'subject_type': 'plate',
      'friendly_name': seed.barcodes.first.human_barcode
    }
  end

  private

  def _add_destination_plate
    return unless properties
    unless has_subjects_with_role_type?(DESTINATION_PLATE_ROLE_TYPE)
      properties[:subjects] = properties[:subjects].push(default_destination_plate_subject)
      @subjects = build_subjects
    end
  end
end