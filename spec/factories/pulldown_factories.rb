# frozen_string_literal: true

# A plate that has exactly the right number of wells!
FactoryBot.define do
  factory(:transfer_plate, class: 'Plate') do
    transient do
      well_count { 3 }
      well_locations do
        Map.where_plate_size(size).where_plate_shape(AssetShape.default).where(column_order: (0...well_count))
      end
    end
    plate_purpose
    size { 96 }

    after(:create) do |plate, evaluator|
      plate.wells << evaluator.well_locations.map { |location| create(:tagged_well, map: location) }
    end
  end

  # A tag group that works for the tag layouts
  sequence(:tag_group_for_layout_name) { |n| "Tag group #{n}" }

  factory(:tag_group_for_layout, class: 'TagGroup') do
    sequence(:name) { |n| "Tag group layout #{n}" }

    transient { tag_sequences { %w[ACGT TGCA] } }

    tags { tag_sequences.each_with_index.map { |oligo, index| build(:tag, map_id: index + 1, oligo: oligo) } }
  end

  # Tag layouts and their templates
  factory :tag_layout_template do
    transient { tags { %w[ACGT TGCA] } }

    sequence(:name) { |n| "Tag Layout Template #{n}" }
    direction_algorithm { 'TagLayout::InColumns' }
    walking_algorithm { 'TagLayout::WalkWellsByPools' }
    tag_group { |target| target.association(:tag_group_for_layout, name: target.name, tag_sequences: target.tags) }

    factory(:inverted_tag_layout_template) do
      direction_algorithm { 'TagLayout::InInverseColumns' }
      walking_algorithm { 'TagLayout::WalkWellsOfPlate' }
    end

    factory(:entire_plate_tag_layout_template) { walking_algorithm { 'TagLayout::WalkWellsOfPlate' } }
  end

  factory :tag_layout_template_submission, class: 'TagLayout::TemplateSubmission' do
    submission
    tag_layout_template
  end

  factory(:tag_layout) do
    user { |target| target.association(:user) }
    plate { |target| target.association(:full_plate_with_samples) }
    tag_group { |target| target.association(:tag_group_for_layout) }

    direction_algorithm { 'TagLayout::InColumns' }
    walking_algorithm { 'TagLayout::WalkWellsOfPlate' }
  end

  factory(:tube_creation) do
    user
    parent factory: %i[full_plate], well_count: 2
    child_purpose factory: %i[child_tube_purpose]

    after(:build) do |tube_creation|
      mock_request_type = create(:library_creation_request_type)

      stock_plate = create(:full_stock_plate, well_count: 2)
      stock_wells = stock_plate.wells

      AssetLink.create!(ancestor: stock_plate, descendant: tube_creation.parent)

      tube_creation
        .parent
        .wells
        .in_column_major_order
        .in_groups_of(tube_creation.parent.wells.size / 2)
        .each_with_index do |pool, i|
          submission = create(:submission)
          pool.each do |well|
            create(:transfer_request, asset: stock_wells[i], target_asset: well, submission: submission)
            mock_request_type.create!(
              asset: stock_wells[i],
              target_asset: well,
              submission: submission,
              request_metadata_attributes: create(:request_metadata_for_library_creation).attributes
            )
            create(:stock_well_link, target_well: well, source_well: stock_wells[i])
          end
        end
    end
  end

  factory(:bait_library_supplier, class: 'BaitLibrary::Supplier') { sequence(:name) { |i| "Bait Library Type #{i}" } }

  factory(:bait_library_type) do
    sequence(:name) { |i| "Bait Library Supplier #{i}" }
    category { 'custom' }
  end

  factory(:bait_library) do
    bait_library_supplier
    bait_library_type
    sequence(:name) { |i| "Bait Library #{i}" }
    target_species { 'Human' }
  end

  factory(:isc_request, class: 'Pulldown::Requests::IscLibraryRequest', aliases: [:pulldown_isc_request]) do
    transient { bait_library { BaitLibrary.first || create(:bait_library) } }

    request_type factory: %i[library_creation_request_type]
    asset { |target| target.association(:well_with_sample_and_plate) }
    target_asset { |target| target.association(:empty_well) }
    request_purpose { :standard }
    request_metadata_attributes do
      {
        fragment_size_required_from: 100,
        fragment_size_required_to: 400,
        bait_library: bait_library,
        library_type: 'Agilent Pulldown'
      }
    end
  end

  factory(:re_isc_request, class: 'Pulldown::Requests::ReIscLibraryRequest') do
    request_type factory: %i[library_request_type]
    asset factory: %i[well_with_sample_and_plate]
    target_asset factory: %i[empty_well]
    request_purpose { :standard }
    request_metadata_attributes do
      {
        fragment_size_required_from: 100,
        fragment_size_required_to: 400,
        bait_library: BaitLibrary.first || create(:bait_library),
        library_type: 'Agilent Pulldown'
      }
    end
  end

  factory(:state_change) do
    contents { %w[A1 D2] }
    reason { 'Plate was passed' }
    target { |target| target.association(:plate) }
    target_state { 'passed' }
    user
  end

  factory(:plate_owner) do
    user
    plate
    eventable { |eventable| eventable.association(:state_change) }
  end
end
