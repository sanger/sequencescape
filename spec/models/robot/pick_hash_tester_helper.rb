# frozen_string_literal: true
class PickHashTesterHelper
  def initialize(destination_plate, picks, time, user)
    @destination_plate = destination_plate
    @picks = picks
    @time = time
    @user = user
  end

  def pickings_for(locations)
    {
      'destination' => {
        @destination_plate.machine_barcode => {
          'name' => 'ABgene 0800',
          'plate_size' => 96,
          'control' => false,
          'mapping' => mappings_for(locations)
        }
      },
      'source' => sources_for_plates(source_plates(locations)),
      'time' => @time,
      'user' => @user.login
    }
  end

  private

  def plate_for_dest_location(location)
    @picks[location][0]
  end

  def source_location_for_dest_location(location)
    @picks[location][1]
  end

  def mappings_for(locations)
    locations.map do |location|
      source_plate = plate_for_dest_location(location)
      source_location = source_location_for_dest_location(location)
      {
        'src_well' => [source_plate.machine_barcode, source_location],
        'dst_well' => location,
        'volume' => nil,
        'buffer_volume' => 0.0
      }
    end
  end

  def source_plates(locations)
    locations.map { |loc| plate_for_dest_location(loc) }
  end

  def sources_for_plates(plates)
    plates.each_with_object({}) do |plate, memo|
      memo[plate.machine_barcode] = {
        'name' => 'ABgene 0800',
        'plate_size' => 96,
        'control' => plate.is_a?(ControlPlate)
      }
    end
  end
end
