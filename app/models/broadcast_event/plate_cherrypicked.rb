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
  validate :robot_present, :source_plates_present, :samples_present, if: :properties


  def robot_present
    unless properties[:subjects].any?{|sub| sub[:role_type] == ROBOT_ROLE_TYPE}
      errors.add(:robot, 'not provided')
    end
  end

  def source_plates_present
    unless properties[:subjects].any?{|sub| sub[:role_type] == SOURCE_PLATES_ROLE_TYPE}
      errors.add(:source_plates, 'not provided')
    end
  end

  def samples_present
    unless properties[:subjects].any?{|sub| sub[:role_type] == SAMPLE_ROLE_TYPE}
      errors.add(:subjects, 'not provided')
    end
  end
end