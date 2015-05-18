#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2014 Genome Research Ltd.
class Robot < ActiveRecord::Base
  include Uuid::Uuidable
  include ModelExtensions::Robot

  validates_presence_of :name,:location
  has_many :robot_properties
  has_one :max_plates_property, :class_name => 'RobotProperty', :conditions => { :key => 'max_plates' }

  named_scope :with_machine_barcode, lambda { |barcode|
    barcode_number = Barcode.number_to_human(barcode)
    { :conditions => [ 'barcode=? AND ?', barcode_number, Barcode.prefix_from_barcode(barcode)==prefix ] }
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
