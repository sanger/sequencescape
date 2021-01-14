# frozen_string_literal: true

# Declares the event of a destination plate created from
# a list of source plates. It requires the following subjects:
#   - Robot - the robot that acted in the cherrypicking process (Beckman)
#   - Samples - all samples that were cherrypicked to build this plate
#   - Source Plates - all source plates that were the source of the cherrypicking
#   - Destination plate **NOT REQUIRED**- the plate that has been cherrypicked into
# If any of these subjects is missing the instance will be considered invalid
# The destination plate subject, if not specified, will be generated from the seed
# as the seed is considered the destination plate.
class BroadcastEvent::PlateCherrypicked < BroadcastEvent
  EVENT_TYPE = 'lh_beckman_cp_destination_created'

  ROBOT_ROLE_TYPE = 'robot'
  SOURCE_PLATES_ROLE_TYPE = 'cherrypicking_source_labware'
  SAMPLE_ROLE_TYPE = 'sample'
  DESTINATION_PLATE_ROLE_TYPE = 'cherrypicking_destination_labware'

  include BroadcastEvent::Helpers::ExternalSubjects

  set_event_type EVENT_TYPE

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

  def user_identifier
    # allows for user identifiers that aren't in the SS db
    properties[:user_identifier].presence || super
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
    BroadcastEvent::SubjectHelpers::Subject.new(DESTINATION_PLATE_ROLE_TYPE, seed).as_json
  end

  private

  def _add_destination_plate
    return unless properties
    return unless seed
    return if subjects_with_role_type?(DESTINATION_PLATE_ROLE_TYPE)

    properties[:subjects].push(default_destination_plate_subject)
    @subjects = build_subjects
  end
end
