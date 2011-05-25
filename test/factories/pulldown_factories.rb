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

Factory.define(:full_plate, :class => Plate) do |plate|
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
  tag_layout.plate     { |target| target.association(:full_plate)           }
  tag_layout.tag_group { |target| target.association(:tag_group_for_layout) }
end

# Plate creations
Factory.define(:parent_plate_purpose, :class => PlatePurpose) do |plate_purpose|
  plate_purpose.name 'Parent plate purpose'

  plate_purpose.after_create do |plate_purpose|
    plate_purpose.child_plate_purposes << Factory(:child_plate_purpose)
  end
end
Factory.define(:child_plate_purpose, :class => PlatePurpose) do |plate_purpose|
  plate_purpose.name 'Child plate purpose'
end
Factory.define(:plate_creation) do |plate_creation|
  plate_creation.parent { |target| target.association(:full_plate) }

  plate_creation.after_build do |plate_creation|
    plate_creation.parent.plate_purpose = PlatePurpose.find_by_name('Parent plate purpose') || Factory(:parent_plate_purpose)
    plate_creation.child_plate_purpose  = PlatePurpose.find_by_name('Child plate purpose')  || Factory(:child_plate_purpose)
  end
end
