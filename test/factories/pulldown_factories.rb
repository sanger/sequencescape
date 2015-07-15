#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.
# A plate that has exactly the right number of wells!
Factory.define(:transfer_plate, :class => Plate) do |plate|
  plate.size 96

  plate.after_create do |plate|
    plate.wells.import(
      [ 'A1', 'B1', 'C1' ].map do |location|
        map = Map.where_description(location).where_plate_size(plate.size).where_plate_shape(Map::AssetShape.find_by_name('Standard')).first or raise StandardError, "No location #{location} on plate #{plate.inspect}"
        Factory(:tagged_well, :map => map)
      end
    )
  end
end

# A plate that has exactly the right number of wells!
Factory.define(:pooling_plate, :class => Plate) do |plate|
  plate.size 96
  plate.purpose { Factory :pooling_plate_purpose }

  plate.after_create do |plate|
    plate.wells.import(
      [ 'A1', 'B1', 'C1', 'D1', 'E1','F1' ].map do |location|
        map = Map.where_description(location).where_plate_size(plate.size).where_plate_shape(Map::AssetShape.find_by_name('Standard')).first or raise StandardError, "No location #{location} on plate #{plate.inspect}"
        Factory(:tagged_well, :map => map)
      end
    )
  end
end


Factory.define(:source_transfer_plate, :parent => :transfer_plate) do |plate|
  plate.after_build do |plate|
    plate.plate_purpose = PlatePurpose.find_by_name('Parent plate purpose') || Factory(:parent_plate_purpose)
  end
end

Factory.define(:destination_transfer_plate, :parent => :transfer_plate) do |plate|
  plate.after_build do |plate|
    plate.plate_purpose = PlatePurpose.find_by_name('Child plate purpose') || Factory(:child_plate_purpose)
  end
end

Factory.define(:initial_downstream_plate, :parent => :transfer_plate) do |plate|
  plate.after_build do |plate|
    plate.plate_purpose = PlatePurpose.find_by_name('Initial downstream plate purpose') || Factory(:initial_downstream_plate_purpose)
  end
end

Factory.define(:full_plate, :class => Plate) do |plate|
  plate.size 96

  plate.after_build do |plate|
    plate.plate_purpose = PlatePurpose.find_by_name('Parent plate purpose') || Factory(:parent_plate_purpose)
  end

  plate.after_create do |plate|
    plate.wells.import(Map.where_plate_size(plate.size).where_plate_shape(plate.asset_shape).all.map { |map| Factory(:well, :map => map) })
  end
end

Factory.define(:full_stock_plate, :class => Plate) do |plate|
  plate.size 96

  plate.after_build do |plate|
    plate.plate_purpose = PlatePurpose.stock_plate_purpose
  end

  plate.after_create do |plate|
    plate.wells.import(Map.where_plate_size(plate.size).where_plate_shape(plate.asset_shape).all.map { |map| Factory(:well, :map => map) })
  end
end

Factory.define(:partial_plate, :class => Plate) do |plate|
  plate.size 96

  plate.after_build do |plate|
    plate.plate_purpose = PlatePurpose.stock_plate_purpose
  end

  plate.after_create do |plate|
    plate.wells.import(Map.where_plate_size(plate.size).where_plate_shape(plate.asset_shape).in_column_major_order.slice(0,48).map { |map| Factory(:well, :map => map) })
  end
end

Factory.define(:two_column_plate, :class => Plate) do |plate|
  plate.size 96

  plate.after_build do |plate|
    plate.plate_purpose = PlatePurpose.stock_plate_purpose
  end

  plate.after_create do |plate|
    plate.wells.import(Map.where_plate_size(plate.size).where_plate_shape(plate.asset_shape).in_column_major_order.slice(0,16).map { |map| Factory(:well, :map => map) })
  end
end

Factory.define(:full_plate_with_samples, :parent => :full_plate) do |plate|
  plate.after_create do |plate|
    plate.wells.each { |well| well.aliquots.create!(:sample => Factory(:sample)) }
  end
end

# Transfers and their templates
Factory.define(:transfer_between_plates, :class => Transfer::BetweenPlates) do |transfer|
  transfer.user        { |target| target.association(:user) }
  transfer.source      { |target| target.association(:source_transfer_plate) }
  transfer.destination { |target| target.association(:destination_transfer_plate) }
  transfer.transfers('A1' => 'A1', 'B1' => 'B1')
end

Factory.define(:transfer_from_plate_to_tube, :class => Transfer::FromPlateToTube) do |transfer|
  transfer.user        { |target| target.association(:user) }
  transfer.source      { |target| target.association(:source_transfer_plate) }
  transfer.destination { |target| target.association(:library_tube)   }
  transfer.transfers([ 'A1', 'B1' ])

  transfer.after_build do |transfer|
    transfer.source.plate_purpose.child_relationships.create!(:child => transfer.destination.purpose, :transfer_request_type => RequestType.transfer)
  end
end

Factory.define(:transfer_template) do |transfer_template|
  transfer_template.transfer_class_name 'Transfer::BetweenPlates'
  transfer_template.transfers('A1' => 'A1', 'B1' => 'B1')
end

Factory.define(:pooling_transfer_template, :class => TransferTemplate) do |transfer_template|
  transfer_template.transfer_class_name 'Transfer::BetweenPlatesBySubmission'
end

Factory.define(:multiplex_transfer_template, :class => TransferTemplate) do |transfer_template|
  transfer_template.transfer_class_name 'Transfer::FromPlateToTubeByMultiplex'
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
  tag_layout_template.direction_algorithm 'TagLayout::InColumns'
  tag_layout_template.walking_algorithm   'TagLayout::WalkWellsByPools'
  tag_layout_template.tag_group { |target| target.association(:tag_group_for_layout) }
end
Factory.define(:inverted_tag_layout_template, :class => TagLayoutTemplate) do |tag_layout_template|
  tag_layout_template.direction_algorithm 'TagLayout::InInverseColumns'
  tag_layout_template.walking_algorithm   'TagLayout::WalkWellsOfPlate'
  tag_layout_template.tag_group { |target| target.association(:tag_group_for_layout) }
end
Factory.define(:entire_plate_tag_layout_template, :class => TagLayoutTemplate) do |tag_layout_template|
  tag_layout_template.direction_algorithm 'TagLayout::InColumns'
  tag_layout_template.walking_algorithm   'TagLayout::WalkWellsOfPlate'
  tag_layout_template.tag_group { |target| target.association(:tag_group_for_layout) }
end

Factory.define(:tag_layout) do |tag_layout|
  tag_layout.user      { |target| target.association(:user) }
  tag_layout.plate     { |target| target.association(:full_plate_with_samples) }
  tag_layout.tag_group { |target| target.association(:tag_group_for_layout)    }

  tag_layout.direction_algorithm 'TagLayout::InColumns'
  tag_layout.walking_algorithm   'TagLayout::WalkWellsByPools'

  # Factory girl builds things in bits, rather than all at once, so we need to trigger the after_initialize call
  # after the instance has been built so that the correct behaviours are installed.
  tag_layout.after_build { |tag_layout| tag_layout.after_initialize }
end

# Plate creations
Factory.define(:parent_plate_purpose, :class => PlatePurpose) do |plate_purpose|
  plate_purpose.name 'Parent plate purpose'

  plate_purpose.after_create do |plate_purpose|
    plate_purpose.child_relationships.create!(:child => Factory(:child_plate_purpose), :transfer_request_type => RequestType.transfer)
  end
end
Factory.define(:pooling_transfer, :class=>RequestType) do |pooling_transfer|
  pooling_transfer.asset_type 'Well'
  pooling_transfer.order 1
  pooling_transfer.request_class_name 'IlluminaHtp::Requests::PcrXpToPool'
end
# Plate creations
Factory.define(:pooling_plate_purpose, :class => PlatePurpose) do |plate_purpose|
  plate_purpose.name 'Pooling plate purpose'
  plate_purpose.can_be_considered_a_stock_plate true
  plate_purpose.after_create do |plate_purpose|
    plate_purpose.child_relationships.create!(:child => Factory(:child_plate_purpose), :transfer_request_type => Factory(:pooling_transfer))
    plate_purpose.child_relationships.create!(:child => Factory(:initial_downstream_plate_purpose), :transfer_request_type => Factory(:pooling_transfer))
  end
end
Factory.define(:child_plate_purpose, :class => PlatePurpose) do |plate_purpose|
  plate_purpose.name 'Child plate purpose'
end
Factory.define(:initial_downstream_plate_purpose, :class=>Pulldown::InitialDownstreamPlatePurpose) do |plate_purpose|
   plate_purpose.name 'Initial Downstream plate purpose'
end
Factory.define(:plate_creation) do |plate_creation|
  plate_creation.user   { |target| target.association(:user) }
  plate_creation.parent { |target| target.association(:full_plate) }

  plate_creation.after_build do |plate_creation|
    plate_creation.parent.plate_purpose = PlatePurpose.find_by_name('Parent plate purpose') || Factory(:parent_plate_purpose)
    plate_creation.child_purpose        = PlatePurpose.find_by_name('Child plate purpose')  || Factory(:child_plate_purpose)
  end
end

# Tube creations
Factory.define(:child_tube_purpose, :class => Tube::Purpose) do |plate_purpose|
  plate_purpose.name 'Child tube purpose'
end
Factory.define(:tube_creation) do |tube_creation|
  tube_creation.user   { |target| target.association(:user) }
  tube_creation.parent { |target| target.association(:full_plate) }

  tube_creation.after_build do |tube_creation|
    tube_creation.parent.plate_purpose = PlatePurpose.find_by_name('Parent plate purpose') || Factory(:parent_plate_purpose)
    tube_creation.child_purpose        = Tube::Purpose.find_by_name('Child tube purpose')  || Factory(:child_tube_purpose)
    mock_request_type                  = Factory(:library_creation_request_type)

    # Ensure that the parent plate will pool into two children by setting up a dummy stock plate
    stock_plate = PlatePurpose.find(2).create!(:do_not_create_wells, :barcode => '999999') { |p| p.wells = [Factory(:empty_well),Factory(:empty_well)] }
    stock_wells  = stock_plate.wells

    AssetLink.create!(:ancestor => stock_plate, :descendant => tube_creation.parent)

    tube_creation.parent.wells.in_column_major_order.in_groups_of(tube_creation.parent.wells.size/2).each_with_index do |pool,i|
      submission  = Submission.create!(:user => Factory(:user))
      pool.each do |well|
        RequestType.transfer.create!(:asset => stock_wells[i], :target_asset => well, :submission => submission);
        mock_request_type.create!(:asset => stock_wells[i], :target_asset => well, :submission => submission, :request_metadata_attributes=>Factory(:request_metadata_for_library_creation).attributes);
        Well::Link.create!(:type=>'stock', :target_well=>well, :source_well=>stock_wells[i])
      end
    end
  end
end

Factory.define(:bait_library_supplier, :class => BaitLibrary::Supplier) do |supplier|
  supplier.name 'bait library supplier'
end
Factory.define(:bait_library_type) do |bait_library_type|
  bait_library_type.name 'bait library type'
end
Factory.define(:bait_library) do |bait_library|
  bait_library.bait_library_supplier { |target| target.association(:bait_library_supplier) }
  bait_library.bait_library_type { |target| target.association(:bait_library_type) }
  bait_library.name 'bait library!'
  bait_library.target_species 'Human'
end

Factory.define(:pulldown_wgs_request, :class => Pulldown::Requests::WgsLibraryRequest) do |request|
  request.request_type { |target| RequestType.find_by_name('Pulldown WGS') or raise StandardError, "Could not find 'Pulldown WGS' request type" }
  request.asset        { |target| target.association(:well_with_sample_and_plate) }
  request.target_asset { |target| target.association(:empty_well) }
  request.after_build do |request|
    request.request_metadata.fragment_size_required_from = 300
    request.request_metadata.fragment_size_required_to   = 500
  end
end

Factory.define(:library_completion, :class => IlluminaHtp::Requests::LibraryCompletion) do |request|
  request.request_type { |target| RequestType.find_by_name('Illumina-B Pooled') or raise StandardError, "Could not find 'Illumina-B Pooled' request type" }
  request.asset        { |target| target.association(:well_with_sample_and_plate) }
  request.target_asset { |target| target.association(:empty_well) }
  request.after_build do |request|
    request.request_metadata.fragment_size_required_from = 300
    request.request_metadata.fragment_size_required_to   = 500
  end
end

Factory.define(:pulldown_sc_request, :class => Pulldown::Requests::ScLibraryRequest) do |request|
  request.request_type { |target| RequestType.find_by_name('Pulldown SC') or raise StandardError, "Could not find 'Pulldown SC' request type" }
  request.asset        { |target| target.association(:well_with_sample_and_plate) }
  request.target_asset { |target| target.association(:empty_well) }
  request.after_build do |request|
    request.request_metadata.fragment_size_required_from = 100
    request.request_metadata.fragment_size_required_to   = 400
    request.request_metadata.bait_library                = Factory(:bait_library)
  end
end
Factory.define(:pulldown_isc_request, :class => Pulldown::Requests::IscLibraryRequest) do |request|
  request.request_type { |target| RequestType.find_by_name('Pulldown ISC') or raise StandardError, "Could not find 'Pulldown ISC' request type" }
  request.asset        { |target| target.association(:well_with_sample_and_plate) }
  request.target_asset { |target| target.association(:empty_well) }
  request.after_build do |request|
    request.request_metadata.fragment_size_required_from = 100
    request.request_metadata.fragment_size_required_to   = 400
    request.request_metadata.bait_library                = BaitLibrary.first||Factory(:bait_library)
  end
end
