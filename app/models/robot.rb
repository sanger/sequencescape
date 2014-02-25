class Robot < ActiveRecord::Base
  include Uuid::Uuidable
  include ModelExtensions::Robot
  validates_presence_of :name,:location
  has_many :robot_properties
  has_one :max_plates_property, :class_name => 'RobotProperty', :conditions => { :key => 'max_plates' }

  named_scope :with_machine_barcode, lambda { |barcode|
    barcode_number = Barcode.number_to_human(source_barcode)
    { :conditions => [ 'barcode=?', barcode_number ] }
  }

  named_scope :include_properties, { :include => :robot_properties }

  def max_beds
    max_plates_property.try(:value).to_i
  end

  def self.prefix
    "RB"
  end

  def self.find_from_barcode(code)
    human_robot_barcode = Barcode.number_to_human(code)
    Robot.find_by_barcode(human_robot_barcode) || Robot.find_by_id(human_robot_barcode)
  end

  def self.valid_barcode?(code)
    Barcode.barcode_to_human!(code, self.prefix)
    self.find_from_barcode(code) # an exception is raise if not found
    true
  rescue
    false
  end
end
