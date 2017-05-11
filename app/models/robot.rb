# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

class Robot < ActiveRecord::Base
  include Uuid::Uuidable
  include ModelExtensions::Robot
  validates_presence_of :name
  validates_presence_of :location
  has_many :robot_properties
  has_one :max_plates_property, ->() { where(key: 'max_plates') }, class_name: 'RobotProperty'

 scope :with_machine_barcode, ->(barcode) {
    return none unless Barcode.prefix_from_barcode(barcode) == prefix
    where(barcode: Barcode.number_to_human(barcode))
                              }

  scope :include_properties, -> { includes(:robot_properties) }

  def max_beds
    max_plates_property.try(:value).to_i
  end

  def self.prefix
    'RB'
  end

  def self.find_from_barcode(code)
    human_robot_barcode = Barcode.number_to_human(code)
    Robot.find_by(barcode: human_robot_barcode) || Robot.find_by(id: human_robot_barcode)
  end

  def self.valid_barcode?(code)
    Barcode.barcode_to_human!(code, prefix)
    find_from_barcode(code) # an exception is raise if not found
    true
  rescue
    false
  end

  def ean13_barcode
    str = Barcode.calculate_barcode(Robot.prefix, barcode.to_i).to_s
    if str.length == 12
      '0' + str
    else
      str
    end
  end

  def sanger_human_barcode
    Robot.prefix + barcode.to_s + Barcode.calculate_checksum(Robot.prefix, barcode.to_i)
  end

end
