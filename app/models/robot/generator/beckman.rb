# frozen_string_literal: true

# Handles picking file generation for Beckman robots
# TODO: Include module of shared behaviour, rather than inheriting
class Robot::Generator::Beckman < Robot::Generator::Hamilton
  # def filename
  #   "#{@batch.id}_batch_#{@plate_barcode}.csv"
  # end
  # def as_text
  #   mapping(picking_data)
  # end
end
