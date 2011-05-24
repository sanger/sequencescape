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

Factory.define(:tag_layout_plate, :class => Plate) do |plate|
  plate.size 96

  plate.after_create do |plate|
    Map.where_plate_size(plate.size).all.each do |map|
      plate.wells << Factory(:well, :map => map)
    end
  end
end

# Transfers and their templates
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

# A tag group that works for the tag layouts
Factory.sequence(:tag_group_for_layout_name) { |n| "Tag group #{n}" }
Factory.define(:tag_group_for_layout, :class => TagGroup) do |tag_group|
  tag_group.name { |_| Factory.next(:tag_group_for_layout_name) }

  tag_group.after_create do |tag_group|
    [ 'ACGT', 'TGCA' ].each_with_index do |oligo, index|
      tag_group.tags.create!(:map_id => index+1, :oligo => oligo)
    end
  end
end

# Tag layouts and their templates
Factory.define(:tag_layout_template) do |tag_layout_template|
  tag_layout_template.layout_class_name 'TagLayout::InColumns'
  tag_layout_template.tag_group { |target| target.association(:tag_group_for_layout) }
end

Factory.define(:tag_layout, :class => TagLayout::InColumns) do |tag_layout|
  tag_layout.plate     { |target| target.association(:tag_layout_plate)     }
  tag_layout.tag_group { |target| target.association(:tag_group_for_layout) }
end
