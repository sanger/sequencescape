# frozen_string_literal: true

require_dependency 'robot'

# Handles picking file generation for Hamilton robots
class Robot::Generator::Hamilton < Robot::Generator::Base
  def self.action
    :hamilton_csv_file
  end

  def filename
    "#{@batch.id}_batch_#{@plate_barcode}.csv"
  end

  def as_text
    @batch.hamilton_csv_file_as_text(@plate_barcode)
  end
end
