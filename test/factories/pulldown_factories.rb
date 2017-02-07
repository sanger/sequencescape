# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.
# A plate that has exactly the right number of wells!
FactoryGirl.define do
  factory(:transfer_plate, class: Plate) do |plate|
    size 96

    after(:create) do |plate|
      plate.wells.import(
        ['A1', 'B1', 'C1'].map do |location|
          map = Map.where_description(location).where_plate_size(plate.size).where_plate_shape(AssetShape.find_by_name('Standard')).first or raise StandardError, "No location #{location} on plate #{plate.inspect}"
          create(:tagged_well, map: map)
        end
      )
    end
  end

  # A plate that has exactly the right number of wells!
  factory(:pooling_plate, class: Plate) do |plate|
    size 96
    purpose { create :pooling_plate_purpose }

    after(:create) do |plate|
      plate.wells.import(
        %w(A1 B1 C1 D1 E1 F1).map do |location|
          map = Map.where_description(location).where_plate_size(plate.size).where_plate_shape(AssetShape.find_by_name('Standard')).first or raise StandardError, "No location #{location} on plate #{plate.inspect}"
          create(:tagged_well, map: map)
        end
      )
    end
  end

  factory(:source_transfer_plate, parent: :transfer_plate) do |plate|
    after(:build) do |plate|
      plate.plate_purpose = PlatePurpose.find_by_name('Parent plate purpose') || create(:parent_plate_purpose)
    end
  end

  factory(:destination_transfer_plate, parent: :transfer_plate) do |plate|
    after(:build) do |plate|
      plate.plate_purpose = PlatePurpose.find_by_name('Child plate purpose') || create(:child_plate_purpose)
    end
  end

  factory(:initial_downstream_plate, parent: :transfer_plate) do |plate|
    after(:build) do |plate|
      plate.plate_purpose = PlatePurpose.find_by_name('Initial downstream plate purpose') || create(:initial_downstream_plate_purpose)
    end
  end

  factory(:full_plate, class: Plate) do |plate|
    size 96

    after(:build) do |plate|
      plate.plate_purpose = PlatePurpose.find_by_name('Parent plate purpose') || create(:parent_plate_purpose)
    end

    after(:create) do |plate|
      plate.wells.import(Map.where_plate_size(plate.size).where_plate_shape(plate.asset_shape).all.map { |map| create(:well, map: map) })
    end
  end

  factory(:full_stock_plate, class: Plate) do |plate|
    size 96
    plate_purpose { PlatePurpose.stock_plate_purpose }

    after(:create) do |plate|
      plate.wells.import(Map.where_plate_size(plate.size).where_plate_shape(plate.asset_shape).all.map { |map| create(:well, map: map) })
    end
  end

  factory(:partial_plate, class: Plate) do |plate|
    size 96
    plate_purpose { PlatePurpose.stock_plate_purpose }

    after(:create) do |plate|
      plate.wells.import(Map.where_plate_size(plate.size).where_plate_shape(plate.asset_shape).in_column_major_order.slice(0, 48).map { |map| create(:well, map: map) })
    end
  end

  factory(:two_column_plate, class: Plate) do |plate|
    size 96
    plate_purpose { PlatePurpose.stock_plate_purpose }

    after(:create) do |plate|
      plate.wells.import(Map.where_plate_size(plate.size).where_plate_shape(plate.asset_shape).in_column_major_order.slice(0, 16).map { |map| create(:well, map: map) })
    end
  end

  factory(:full_plate_with_samples, parent: :full_plate) do |plate|
    after(:create) do |plate|
      plate.wells.each { |well| create :aliquot, receptacle: well }
    end
  end

  # Transfers and their templates
  factory(:transfer_between_plates, class: Transfer::BetweenPlates) do |transfer|
    user        { |target| target.association(:user) }
    source      { |target| target.association(:source_transfer_plate) }
    destination { |target| target.association(:destination_transfer_plate) }
    transfers('A1' => 'A1', 'B1' => 'B1')
  end

  factory(:transfer_from_plate_to_tube, class: Transfer::FromPlateToTube) do |transfer|
    user        { |target| target.association(:user) }
    source      { |target| target.association(:source_transfer_plate) }
    destination { |target| target.association(:library_tube) }
    transfers(['A1', 'B1'])

    after(:build) do |transfer|
      transfer.source.plate_purpose.child_relationships.create!(child: transfer.destination.purpose, transfer_request_type: RequestType.transfer)
    end
  end

  factory(:transfer_template) do |transfer_template|
    transfer_class_name 'Transfer::BetweenPlates'
    transfers('A1' => 'A1', 'B1' => 'B1')
  end

  factory(:pooling_transfer_template, class: TransferTemplate) do |transfer_template|
    transfer_class_name 'Transfer::BetweenPlatesBySubmission'
  end

  factory(:multiplex_transfer_template, class: TransferTemplate) do |transfer_template|
    transfer_class_name 'Transfer::FromPlateToTubeByMultiplex'
  end
  # A tag group that works for the tag layouts
  sequence(:tag_group_for_layout_name) { |n| "Tag group #{n}" }

  factory(:tag_group_for_layout, class: TagGroup) do |tag_group|
    name { |_| FactoryGirl.generate(:tag_group_for_layout_name) }

    after(:create) do |tag_group|
      ['ACGT', 'TGCA'].each_with_index do |oligo, index|
        tag_group.tags.create!(map_id: index + 1, oligo: oligo)
      end
    end
  end

  # Tag layouts and their templates
  factory(:tag_layout_template) do |tag_layout_template|
    direction_algorithm 'TagLayout::InColumns'
    walking_algorithm   'TagLayout::WalkWellsByPools'
    tag_group { |target| target.association(:tag_group_for_layout) }
  end
  factory(:inverted_tag_layout_template, class: TagLayoutTemplate) do |tag_layout_template|
    direction_algorithm 'TagLayout::InInverseColumns'
    walking_algorithm   'TagLayout::WalkWellsOfPlate'
    tag_group { |target| target.association(:tag_group_for_layout) }
  end
  factory(:entire_plate_tag_layout_template, class: TagLayoutTemplate) do |tag_layout_template|
    direction_algorithm 'TagLayout::InColumns'
    walking_algorithm   'TagLayout::WalkWellsOfPlate'
    tag_group { |target| target.association(:tag_group_for_layout) }
  end

  factory(:tag_layout) do |tag_layout|
    user      { |target| target.association(:user) }
    plate     { |target| target.association(:full_plate_with_samples) }
    tag_group { |target| target.association(:tag_group_for_layout)    }

    direction_algorithm 'TagLayout::InColumns'
    walking_algorithm   'TagLayout::WalkWellsByPools'

    # FactoryGirl girl builds things in bits, rather than all at once, so we need to trigger the after_initialize call
    # after the instance has been built so that the correct behaviours are installed.
    after(:build) { |tag_layout| tag_layout.import_behaviour }
  end

  # Plate creations
  factory(:parent_plate_purpose, class: PlatePurpose) do |plate_purpose|
    name 'Parent plate purpose'

    after(:create) do |plate_purpose|
      plate_purpose.child_relationships.create!(child: create(:child_plate_purpose), transfer_request_type: RequestType.transfer)
    end
  end
  factory(:pooling_transfer, class: RequestType) do |pooling_transfer|
    asset_type 'Well'
    order 1
    request_class_name 'TransferRequest::InitialDownstream'
    request_purpose { |rp| rp.association(:request_purpose) }
  end
  # Plate creations
  factory(:pooling_plate_purpose, class: PlatePurpose) do |plate_purpose|
    name 'Pooling plate purpose'
    can_be_considered_a_stock_plate true
    after(:create) do |plate_purpose|
      plate_purpose.child_relationships.create!(child: create(:child_plate_purpose), transfer_request_type: create(:pooling_transfer))
      plate_purpose.child_relationships.create!(child: create(:initial_downstream_plate_purpose), transfer_request_type: create(:pooling_transfer))
    end
  end
  factory(:child_plate_purpose, class: PlatePurpose) do |plate_purpose|
    name 'Child plate purpose'
  end
  factory(:initial_downstream_plate_purpose, class: Pulldown::InitialDownstreamPlatePurpose) do |plate_purpose|
     plate_purpose.name 'Initial Downstream plate purpose'
  end
  factory(:plate_creation) do |plate_creation|
    user   { |target| target.association(:user) }
    parent { |target| target.association(:full_plate) }

    after(:build) do |plate_creation|
      plate_creation.parent.plate_purpose = PlatePurpose.find_by_name('Parent plate purpose') || create(:parent_plate_purpose)
      plate_creation.child_purpose        = PlatePurpose.find_by_name('Child plate purpose')  || create(:child_plate_purpose)
    end
  end

  # Tube creations
  factory(:child_tube_purpose, class: Tube::Purpose) do |plate_purpose|
    name 'Child tube purpose'
  end
  factory(:tube_creation) do |tube_creation|
    user   { |target| target.association(:user) }
    parent { |target| target.association(:full_plate) }

    after(:build) do |tube_creation|
      user = create(:user)

      tube_creation.parent.plate_purpose = PlatePurpose.find_by_name('Parent plate purpose') || create(:parent_plate_purpose)
      tube_creation.child_purpose        = Tube::Purpose.find_by_name('Child tube purpose')  || create(:child_tube_purpose)
      mock_request_type                  = create(:library_creation_request_type)

      # Ensure that the parent plate will pool into two children by setting up a dummy stock plate
      stock_plate = PlatePurpose.find(2).create!(:do_not_create_wells, barcode: '999999') { |p| p.wells = [create(:empty_well), create(:empty_well)] }
      stock_wells = stock_plate.wells

      AssetLink.create!(ancestor: stock_plate, descendant: tube_creation.parent)

      tube_creation.parent.wells.in_column_major_order.in_groups_of(tube_creation.parent.wells.size / 2).each_with_index do |pool, i|
        submission = Submission.create!(user: user)
        pool.each do |well|
          RequestType.transfer.create!(asset: stock_wells[i], target_asset: well, submission: submission);
          mock_request_type.create!(asset: stock_wells[i], target_asset: well, submission: submission, request_metadata_attributes: create(:request_metadata_for_library_creation).attributes);
          Well::Link.create!(type: 'stock', target_well: well, source_well: stock_wells[i])
        end
      end
    end
  end

  factory(:bait_library_supplier, class: BaitLibrary::Supplier) do |supplier|
    name 'bait library supplier'
  end
  factory(:bait_library_type) do |bait_library_type|
    name 'bait library type'
  end
  factory(:bait_library) do |bait_library|
    bait_library_supplier { |target| target.association(:bait_library_supplier) }
    bait_library_type { |target| target.association(:bait_library_type) }
    name 'bait library!'
    target_species 'Human'
  end

  factory(:pulldown_wgs_request, class: Pulldown::Requests::WgsLibraryRequest) do |request|
    request_type { |target| RequestType.find_by_name('Pulldown WGS') or raise StandardError, "Could not find 'Pulldown WGS' request type" }
    asset        { |target| target.association(:well_with_sample_and_plate) }
    target_asset { |target| target.association(:empty_well) }
    after(:build) do |request|
      request.request_metadata.fragment_size_required_from = 300
      request.request_metadata.fragment_size_required_to   = 500
    end
    request_purpose { |rp| rp.association(:request_purpose) }
  end
  factory(:pulldown_sc_request, class: Pulldown::Requests::ScLibraryRequest) do |request|
    request_type { |target| RequestType.find_by_name('Pulldown SC') or raise StandardError, "Could not find 'Pulldown SC' request type" }
    asset        { |target| target.association(:well_with_sample_and_plate) }
    target_asset { |target| target.association(:empty_well) }
    after(:build) do |request|
      request.request_metadata.fragment_size_required_from = 100
      request.request_metadata.fragment_size_required_to   = 400
      request.request_metadata.bait_library                = create(:bait_library)
    end
    request_purpose { |rp| rp.association(:request_purpose) }
  end
  factory(:pulldown_isc_request, class: Pulldown::Requests::IscLibraryRequest) do |request|
    request_type { |target| RequestType.find_by_name('Pulldown ISC') or raise StandardError, "Could not find 'Pulldown ISC' request type" }
    asset        { |target| target.association(:well_with_sample_and_plate) }
    target_asset { |target| target.association(:empty_well) }
    request_purpose { |rp| rp.association(:request_purpose) }
    after(:build) do |request|
      request.request_metadata.fragment_size_required_from = 100
      request.request_metadata.fragment_size_required_to   = 400
      request.request_metadata.bait_library                = BaitLibrary.first || create(:bait_library)
    end
  end

  factory(:state_change) do
    user
    target { |target| target.association(:plate) }
    target_state "passed"
  end

  factory(:plate_owner) do
    user
    plate
    eventable { |eventable| eventable.association(:state_change) }
  end
end
