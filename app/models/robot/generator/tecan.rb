# frozen_string_literal: true

require_dependency 'robot'

# Handles picking file generation for Tecan robots
class Robot::Generator::Tecan < Robot::Generator::Base
  def self.action
    :gwl_file
  end

  def filename
    "#{@batch.id}_batch_#{@plate_barcode}.gwl"
  end

  def as_text
    Sanger::Robots::Tecan::Generator.mapping(picking_data, @batch.total_volume_to_cherrypick.to_i)
  end
end
