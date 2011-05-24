# A plate that has exactly the right number of wells!
Factory.define(:transfer_plate, :class => Plate) do |plate|
  plate.size 96

  plate.after_create do |plate|
    [ 'A1', 'B1' ].each do |location|
      map = Map.where_description(location).where_plate_size(plate.size).first or raise StandardError, "No location #{location} on plate #{plate.inspect}"
      plate.wells << Factory(:well, :map => map)
    end
  end
end

Factory.define(:transfer_between_plates, :class => Transfer::BetweenPlates) do |transfer|
  transfer.source      { |target| target.association(:transfer_plate) }
  transfer.destination { |target| target.association(:transfer_plate) }
  transfer.transfers('A1' => 'A1', 'B1' => 'B1')
end

Factory.define(:transfer_from_plate_to_tube, :class => Transfer::FromPlateToTube) do |transfer|
  transfer.source      { |target| target.association(:transfer_plate) }
  transfer.destination { |target| target.association(:library_tube)   }
  transfer.transfers([ 'A1', 'B1' ])
end

Factory.define(:transfer_template) do |transfer_template|
  transfer_template.transfer_class_name 'Transfer::BetweenPlates'
  transfer_template.transfers('A1' => 'A1', 'B1' => 'B1')
end
