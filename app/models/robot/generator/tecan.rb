# frozen_string_literal: true

require_dependency 'robot'
require_dependency 'robot/verification'

# Handles picking file generation for Tecan robots
class Robot::Generator::Tecan < Robot::Generator::Base
  def filename
    "#{@batch.id}_batch_#{@plate_barcode}.gwl"
  end

  def as_text
    @batch.tecan_gwl_file_as_text(@plate_barcode, @batch.total_volume_to_cherrypick)
  end
end
