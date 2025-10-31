# frozen_string_literal: true

# Please note: This is a new file to help improve factory organization.
# Some requests factories may exist elsewhere, especially in the domain
# files, such as pipelines and in the catch all factory folder.
# Create all new request factories here, and move others as you find them,
# especially if you change them, otherwise merges could get messy.

# The factories in here, at time of writing could do with a bit of TLC.
# - Remove references to existing request types, build one instead!
# - All factories MUST be valid unless begining with invalid_ (allows us to lint factory bot)
# - Factories names after a class, eg. request, should NOT inherit. Use traits if there is shared behaviour.
# - Factories names after a class should avoid creating associations, except where they are required for the
#   request to be valid.
FactoryBot.define do
  factory :multiplexed_library_creation_request, parent: :request do
    sti_type { 'MultiplexedLibraryCreationRequest' }
    asset { |asset| asset.association(:sample_tube) }
    target_asset { |asset| asset.association(:library_tube) }
    request_type factory: %i[multiplexed_library_creation_request_type]
    request_metadata_attributes do
      { fragment_size_required_from: 150, fragment_size_required_to: 400, library_type: 'Standard' }
    end
  end

  %w[failed passed pending cancelled].each do |request_state|
    factory :"#{request_state}_request", parent: :request do
      state { request_state }
    end
  end

  factory :request_base, class: 'Request' do
    request_type
    request_purpose { :standard }
    sti_type { request_type.request_class_name }
    request_metadata_attributes do
      FactoryBot.factories.registered?(metadata_factory) ? attributes_for(metadata_factory) : {}
    end

    transient { metadata_factory { :"request_metadata_for_#{request_type.name.downcase.gsub(/[^a-z]+/, '_')}" } }

    factory :customer_request, class: 'CustomerRequest' do
      sti_type { 'CustomerRequest' } # Oddly, this seems to be necessary!
      request_type factory: %i[customer_request_type]
    end

    factory :create_asset_request do
      sti_type { 'CreateAssetRequest' } # Oddly, this seems to be necessary!
    end
  end

  factory :sequencing_request, class: 'SequencingRequest' do
    request_type factory: %i[sequencing_request_type]
    request_purpose { :standard }
    sti_type { 'SequencingRequest' }
    request_metadata_attributes { attributes_for(:request_metadata_for_standard_sequencing_with_read_length) }

    factory(:sequencing_request_with_assets) do
      asset factory: %i[library_tube]
      target_asset factory: %i[lane]
    end

    factory(:complete_sequencing_request) do
      transient { event_descriptors { { 'Chip Barcode' => 'fcb' } } }
      asset factory: %i[library_tube]
      target_asset factory: %i[lane]

      after(:build) do |request, evaluator|
        request.lab_events << build(:flowcell_event, descriptors: evaluator.event_descriptors, batch: request.batch)
      end
    end
  end

  factory :element_aviti_sequencing_request, class: 'ElementAvitiSequencingRequest' do
    request_type factory: %i[element_aviti_sequencing]
    request_purpose { :standard }
    sti_type { 'SequencingPipeline' }
    request_metadata_attributes do
      {
        fragment_size_required_from: 150,
        fragment_size_required_to: 400,
        percent_phix_requested: 50,
        requested_flowcell_type: 'HO',
        read_length: 150,
        low_diversity: 'Yes'
      }
    end
  end

  factory :ultima_sequencing_request, class: 'UltimaSequencingRequest' do
    request_type factory: %i[ultima_sequencing]
    request_purpose { :standard }
    sti_type { 'UltimaSequencingRequest' }
    request_metadata_attributes do
      {
        fragment_size_required_from: 150,
        fragment_size_required_to: 400,
        ot_recipe: 'Free'
      }
    end
  end

  factory(:library_creation_request, parent: :request, class: 'LibraryCreationRequest') do
    asset factory: %i[sample_tube]
    request_type factory: %i[library_creation_request_type]

    request_metadata_attributes do
      { fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: 'Standard' }
    end
  end

  # Well based library request as used in eg. Limber pipeline
  factory :library_request, class: 'IlluminaHtp::Requests::StdLibraryRequest' do
    asset factory: %i[well]
    request_type factory: %i[library_request_type]
    request_purpose { :standard }
    request_metadata_attributes { attributes_for(:request_metadata_for_library_manufacture) }

    factory :gbs_request, class: 'IlluminaHtp::Requests::GbsRequest' do
      request_metadata_attributes { attributes_for(:request_metadata_for_gbs) }
    end

    factory :heron_request, class: 'IlluminaHtp::Requests::HeronRequest' do
      request_metadata_attributes { attributes_for(:request_metadata_for_heron) }
    end

    factory :heron_tailed_request, class: 'IlluminaHtp::Requests::HeronTailedRequest' do
      request_metadata_attributes { attributes_for(:request_metadata_for_heron) }
    end
  end

  factory(:multiplex_request, class: 'Request::Multiplexing') do
    asset { nil }
    target_asset factory: %i[multiplexed_library_tube]
    request_type factory: %i[multiplex_request_type]
    request_purpose { :standard }
  end

  factory :cherrypick_request do
    asset factory: %i[well]
    target_asset factory: %i[well]
    request_type factory: %i[cherrypick_request_type]
    request_purpose { :standard }

    # Adds the associations needed for processing down a pipeline
    factory :cherrypick_request_for_pipeline do
      asset factory: %i[well_with_sample_and_plate]
      submission

      factory :passed_cherrypick_request do
        target_asset factory: %i[well_with_sample_and_plate]
        state { 'passed' }
      end
    end
  end

  factory :cherrypick_for_fluidigm_request do
    transient { target_purpose { create(:plate_purpose) } }
    asset factory: %i[well]
    target_asset factory: %i[well]
    request_type factory: %i[cherrypick_request_type]
    request_purpose { :standard }
    request_metadata_attributes { { target_purpose: } }

    factory :final_cherrypick_for_fluidigm_request do
      request_type factory: %i[request_type], key: 'pick_to_fluidigm'
    end
  end

  factory :request_without_assets, parent: :request_base do
    transient { user_login { 'abc123' } }
    project
    state { 'pending' }
    study
    user { User.find_by(login: user_login) || create(:user, login: user_login) }
  end

  factory :request, parent: :request_without_assets do
    # the sample should be setup correctly and the assets should be valid
    asset factory: %i[sample_tube]
    target_asset factory: %i[empty_library_tube]

    factory :request_with_submission do
      after(:build) do |request|
        unless request.submission
          request.submission =
            FactoryHelp.submission(
              study: request.initial_study,
              project: request.initial_project,
              request_types: [request.request_type.try(:id)].compact.map(&:to_s),
              user: request.user,
              assets: [request.asset].compact,
              request_options: request.request_metadata.attributes
            )
        end
      end
    end
  end

  factory :request_with_sequencing_request_type, parent: :request_without_assets do
    # the sample should be setup correctly and the assets should be valid
    asset { |asset| asset.association(:library_tube) }
    request_metadata { |metadata| metadata.association(:request_metadata_for_standard_sequencing) }
    request_type { |rt| rt.association(:sequencing_request_type) }
  end

  factory :well_request, parent: :request_without_assets do
    # the sample should be setup correctly and the assets should be valid
    request_type { |rt| rt.association(:well_request_type) }
    asset { |asset| asset.association(:well) }
    target_asset { |asset| asset.association(:well) }
  end

  factory :request_suitable_for_starting, parent: :request_without_assets do
    asset { |asset| asset.association(:sample_tube) }
    target_asset { |asset| asset.association(:empty_library_tube) }
  end

  factory :lib_pcr_xp_request, parent: :request_without_assets do
    request_type { |rt| rt.association(:lib_pcr_xp_request_type) }
    asset { |asset| asset.association(:well) }
    target_asset { |asset| asset.association(:empty_library_tube) }
  end

  factory :request_traction_grid_ion, class: 'Request::Traction::GridIon' do
    asset factory: %i[well]
    target_asset { nil }
    request_purpose { :standard }
    request_type factory: %i[well_request_type]
    request_metadata_attributes { attributes_for(:request_traction_grid_ion_metadata) }
  end

  factory :request_without_submission, class: 'Request' do
    request_type
    request_purpose { :standard }

    # Ensure that the request metadata is correctly setup based on the request type
    after(:build) do |request|
      next if request.request_type.nil?

      if request.request_metadata.new_record?
        request.request_metadata =
          build(:"request_metadata_for_#{request.request_type.name.downcase.gsub(/[^a-z]+/, '_')}")
      end
      request.sti_type = request.request_type.request_class_name
    end
  end

  factory(
    :request_library_creation,
    class: 'Request::LibraryCreation',
    aliases: [:library_creation_request_for_testing_sequencing_requests]
  ) do
    request_type factory: %i[library_creation_request_type]
    request_purpose { :standard }
    asset { |target| target.association(:well_with_sample_and_plate) }
    target_asset { |target| target.association(:empty_well) }
    request_metadata_attributes { { fragment_size_required_from: 300, fragment_size_required_to: 500 } }
  end

  factory(:external_multiplexed_library_tube_creation_request, class: 'ExternalLibraryCreationRequest') do
    request_type { RequestType.external_multiplexed_library_creation }
    request_purpose { :standard }
    asset { create(:library_tube) }
    target_asset { create(:multiplexed_library_tube) }
  end

  factory :pac_bio_sample_prep_request do |_r|
    target_asset { |ta| ta.association(:pac_bio_library_tube) }
    asset { |a| a.association(:well) }
    submission { |s| s.association(:submission) }
    request_type factory: %i[pac_bio_sample_prep_request_type]
    request_purpose { :standard }
  end

  factory :pac_bio_sequencing_request do
    target_asset { |ta| ta.association(:well) }
    asset { |a| a.association(:pac_bio_library_tube) }
    submission { |s| s.association(:submission) }
    request_type { |s| s.association(:pac_bio_sequencing_request_type) }
    request_purpose { :standard }
  end
end
