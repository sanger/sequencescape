# frozen_string_literal: true

require_dependency 'robot'

# Handles picking file generation for Beckman robots
class Robot::Generator::Beckman < Robot::Generator::Base
  def self.action
    :beckman_csv_file
  end

  def filename
    "#{@batch.id}_batch_#{@plate_barcode}.csv"
  end

  def as_text
    Sanger::Robots::Beckman::Generator.mapping(picking_data)
  end
end
