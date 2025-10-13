# frozen_string_literal: true
class Robot < ApplicationRecord
  include Uuid::Uuidable
  include ModelExtensions::Robot

  validates :name, presence: true
  validates :location, presence: true
  has_many :robot_properties
  has_one :max_plates_property, -> { where(key: 'max_plates') }, class_name: 'RobotProperty'
  has_one :verification_behaviour_property, -> { where(key: 'verification_behaviour') }, class_name: 'RobotProperty'
  has_many :generation_behaviour_properties, -> { where(key: 'generation_behaviour') }, class_name: 'RobotProperty'

  scope :with_barcode,
        ->(barcode) do
          return none unless Barcode.prefix_from_barcode(barcode) == prefix

          where(barcode: Barcode.number_to_human(barcode))
        end
  scope :include_properties, -> { includes(:robot_properties) }
  scope :with_verification_behaviour,
        -> { includes(:robot_properties).where(robot_properties: { key: 'verification_behaviour' }) }

  #
  # Returns an array of all pick numbers associated with the corresponding batch and plate_barcode
  # @note Added as I refactor the batches/_assets.html.erb page. Currently just wraps pick_number_to_expected_layout
  #       and as a result performs a lot of unnecessary work.
  #
  # @param [Batch] batch The Batch to get pick numbers for
  # @param [String] plate_barcode The barcode of the destination plate
  #
  # @return [Array<String>] Array of pick numbers associated with the batch/plate
  #
  def pick_numbers(batch, plate_barcode)
    verification_behaviour.pick_numbers(batch, plate_barcode, max_beds)
  end

  def pick_number_to_expected_layout(batch, plate_barcode)
    verification_behaviour.pick_number_to_expected_layout(batch, plate_barcode, max_beds)
  end

  def all_picks(batch)
    verification_behaviour.all_picks(batch, max_beds)
  end

  def max_beds
    max_plates_property.try(:value).to_i
  end

  def verification_behaviour
    @verification_behaviour ||= verification_class.new
  end

  # Returns the generation behaviour class for the given generator_id
  # Looks up the RobotProperty with the give generator_id and returns the
  # corresponding Robot::Generator class.
  #
  # @param generator_id [Integer] The ID of the generation_behaviour_property to look up.
  # @return [Class] The corresponding Robot::Generator class.
  # @raise [ActiveRecord::RecordNotFound] if no property with the given ID exists.
  def generation_behaviour(generator_id)
    property = generation_behaviour_properties.find(generator_id)
    {
      'Hamilton' => Robot::Generator::Hamilton,
      'Tecan' => Robot::Generator::Tecan,
      'TecanV2' => Robot::Generator::TecanV2,
      'TecanV3' => Robot::Generator::TecanV3,
      'Beckman' => Robot::Generator::Beckman
    }.fetch(property.value)
  end

  # Returns an instance of the generation behaviour for the given parameters.
  #
  # @param batch [Batch] The Batch for which to generate the pick list.
  # @param plate_barcode [String] The barcode of the destination plate.
  # @param pick_number [String] The pick number to generate the pick list for.
  # @param generator_id [Integer] The ID of the generation_behaviour_property to use.
  # @return [Robot::Generator] An instance of the corresponding Robot::Generator class.
  # @raise [ActiveRecord::RecordNotFound] if no property with the given ID exists.
  def generator(batch:, plate_barcode:, pick_number:, generator_id:)
    picking_data = Robot::PickData.new(batch, max_beds:).picking_data_hash(plate_barcode)[pick_number]
    layout = verification_behaviour.layout_data_object(picking_data)
    generation_behaviour(generator_id).new(batch:, plate_barcode:, picking_data:, layout:)
  end

  def self.default_for_verification
    with_verification_behaviour.first || first
  end

  private

  def verification_class
    {
      'Hamilton' => Robot::Verification::SourceDestControlBeds,
      'Beckman' => Robot::Verification::SourceDestControlBeds,
      'SourceDestControlBeds' => Robot::Verification::SourceDestControlBeds,
      'Tecan' => Robot::Verification::SourceDestBeds,
      'SourceDestBeds' => Robot::Verification::SourceDestBeds
    }.fetch(verification_behaviour_property&.value, Robot::Verification::SourceDestBeds)
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
    rescue StandardError
      false
    end
    alias find_from_barcode find_by_barcode
  end
end
