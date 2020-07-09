class Robot < ApplicationRecord
  include Uuid::Uuidable
  include ModelExtensions::Robot

  validates :name, presence: true
  validates :location, presence: true
  has_many :robot_properties
  has_one :max_plates_property, ->() { where(key: 'max_plates') }, class_name: 'RobotProperty'
  has_one :verification_behaviour_property, ->() { where(key: 'verification_behaviour') }, class_name: 'RobotProperty'
  has_one :generation_behaviour_property, ->() { where(key: 'generation_behaviour') }, class_name: 'RobotProperty'

  scope :with_barcode, ->(barcode) {
                         return none unless Barcode.prefix_from_barcode(barcode) == prefix

                         where(barcode: Barcode.number_to_human(barcode))
                       }
  scope :include_properties, -> { includes(:robot_properties) }
  scope :with_verification_behaviour, -> { includes(:robot_properties).where(robot_properties: { key: 'verification_behaviour' }) }

  def pick_number_to_expected_layout(batch, plate_barcode)
    verification_behaviour.pick_number_to_expected_layout(batch, plate_barcode, max_beds)
  end

  def max_beds
    max_plates_property.try(:value).to_i
  end

  def verification_behaviour
    {
      'Hamilton' => Robot::Verification::SourceDestControlBeds,
      'Beckman' => Robot::Verification::SourceDestControlBeds,
      'SourceDestControlBeds' => Robot::Verification::SourceDestControlBeds,
      'Tecan' => Robot::Verification::SourceDestBeds,
      'SourceDestBeds' => Robot::Verification::SourceDestBeds
    }.fetch(verification_behaviour_property&.value, Robot::Verification::SourceDestBeds).new
  end

  def generation_behaviour
    {
      'Hamilton' => Robot::Generator::Hamilton,
      'Tecan' => Robot::Generator::Tecan,
      'Beckman' => Robot::Generator::Beckman
    }.fetch(generation_behaviour_property&.value, Robot::Generator::Tecan)
  end

  def generator(batch:, plate_barcode:, pick_number:)
    picking_data = Robot::PickData.new(batch, plate_barcode, max_beds: max_beds).picking_data_hash[pick_number]
    layout = verification_behaviour.layout_data_object(picking_data)
    generation_behaviour.new(batch: batch, plate_barcode: plate_barcode, picking_data: picking_data, layout: layout)
  end

  class << self
    def prefix
      'RB'
    end

    def find_by_barcode(code)
      human_robot_barcode = Barcode.number_to_human(code)
      Robot.find_by(barcode: human_robot_barcode) || Robot.find_by(id: human_robot_barcode)
    end

    def valid_barcode?(code)
      Barcode.barcode_to_human!(code, prefix)
      find_from_barcode(code) # an exception is raise if not found
      true
    rescue
      false
    end
    alias find_from_barcode find_by_barcode
  end
end
