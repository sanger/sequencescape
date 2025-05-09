# frozen_string_literal: true

FactoryBot.define do
  trait :library_request_validators do
    after(:build) do |request_type|
      request_type.library_types_request_types << create(:library_types_request_type, request_type:)
      request_type.request_type_validators << create(:library_request_type_validator, request_type:)
    end
  end

  trait :with_library_types do
    transient { library_type { build(:library_type) } }

    after(:build) do |request_type, evaluator|
      request_type.library_types_request_types << create(
        :library_types_request_type,
        library_type: evaluator.library_type,
        request_type: request_type
      )
      request_type.request_type_validators << create(:library_request_type_validator, request_type:)
    end
  end

  factory :request_type do
    name { generate(:request_type_name) }
    key { generate(:request_type_key) }
    deprecated { false }
    asset_type { 'SampleTube' }
    request_class { Request }
    order { 1 }
    initial_state { 'pending' }
    request_purpose { :standard }

    factory :customer_request_type do
      request_class { CustomerRequest }
    end

    factory :pbmc_pooling_customer_request_type do
      request_class { PbmcPoolingCustomerRequest }
    end

    factory :cherrypick_request_type do
      request_class { CherrypickRequest }
      asset_type { 'Well' }
      target_asset_type { 'Well' }
    end

    factory :well_request_type do
      asset_type { 'Well' }
      request_class { CustomerRequest }

      factory :library_request_type do
        request_class { IlluminaHtp::Requests::StdLibraryRequest }
        billable { true }
        product_line { ProductLine.create!(name: 'test_product_line') }

        factory :gbs_request_type do
          request_class { IlluminaHtp::Requests::GbsRequest }
        end

        factory :heron_request_type do
          request_class { IlluminaHtp::Requests::HeronRequest }
        end
      end

      factory :multiplex_request_type do
        request_class { Request::Multiplexing }
        billable { false }
        for_multiplexing { true }
        target_purpose factory: %i[tube_purpose]
      end
    end

    factory :library_creation_request_type do
      target_asset_type { 'LibraryTube' }
      request_class { LibraryCreationRequest }

      factory :isc_library_request_type do
        asset_type { 'Well' }
        target_asset_type { 'MultiplexedLibraryTube' }
        request_class { Pulldown::Requests::IscLibraryRequest }
      end
    end

    factory :pac_bio_sequencing_request_type do
      asset_type { 'PacBioLibraryTube' }
      request_class { PacBioSequencingRequest }

      after(:build) do |request_type|
        request_type.request_type_validators = [
          build(
            :request_type_validator,
            request_type: request_type,
            request_option: 'insert_size',
            options: [500, 1000, 2000, 5000, 10_000, 20_000]
          ),
          build(
            :request_type_validator,
            request_type: request_type,
            request_option: 'sequencing_type',
            options: ['Standard', 'MagBead', 'MagBead OneCellPerWell v1']
          )
        ]
      end
    end

    factory :pac_bio_sample_prep_request_type do
      asset_type { 'Well' }
      request_class { PacBioSamplePrepRequest }
    end

    factory :sequencing_request_type do
      transient do
        read_lengths { [37, 54, 76, 108] }
        default { 54 }
      end
      asset_type { 'LibraryTube' }
      request_class { SequencingRequest }

      after(:build) do |request_type, ev|
        srv =
          create(
            :sequencing_request_type_validator,
            request_type: request_type,
            options: ev.read_lengths,
            default: ev.default
          )
        request_type.request_type_validators << srv
      end
    end

    factory :element_aviti_sequencing do
      asset_type { 'LibraryTube' }
      request_class { ElementAvitiSequencingRequest }
    end

    factory :miseq_sequencing_request_type do
      request_class { MiSeqSequencingRequest }
      asset_type { 'LibraryTube' }

      after(:build) do |request_type|
        srv = create(:sequencing_request_type_validator, request_type: request_type, options: [54, 150, 250])
        request_type.request_type_validators << srv
      end
    end

    factory :nova_seq_x_sequencing_request_type do
      request_class { NovaSeqXSequencingRequest }
      transient do
        read_lengths { [50, 100, 150] }
        default { 50 }
      end
      asset_type { 'Well' }

      after(:build) do |request_type, ev|
        srv =
          create(
            :sequencing_request_type_validator,
            request_type: request_type,
            options: ev.read_lengths,
            default: ev.default
          )
        request_type.request_type_validators << srv
      end
    end

    factory :multiplexed_library_creation_request_type do
      request_class { MultiplexedLibraryCreationRequest }
      asset_type { 'SampleTube' }
      for_multiplexing { true }

      after(:build) do |request_type|
        request_type.library_types_request_types << create(:library_types_request_type, request_type:)
        request_type.request_type_validators << create(:library_request_type_validator, request_type:)
      end
    end

    factory :plate_based_multiplexed_library_creation_request_type do
      request_class { MultiplexedLibraryCreationRequest }
      asset_type { 'Well' }
      for_multiplexing { true }

      after(:build) do |request_type|
        request_type.library_types_request_types << create(:library_types_request_type, request_type:)
        request_type.request_type_validators << create(:library_request_type_validator, request_type:)
      end
    end

    factory :validated_request_type do
      after(:create) { |request_type| request_type.extended_validators << create(:extended_validator) }
    end
  end

  factory :extended_validator do
    behaviour { 'SpeciesValidator' }
    options { { taxon_id: 9606 } }
  end

  factory :library_types_request_type do
    request_type
    library_type
    is_default { true }
  end

  factory :request_type_validator, class: 'RequestType::Validator' do
    transient do
      options { [37, 54, 76, 108] }
      default { options.first }
    end

    request_option { 'read_length' }
    request_type
    valid_options { RequestType::Validator::ArrayWithDefault.new(options, default) }

    factory :sequencing_request_type_validator do
      default { 54 }
      request_type factory: %i[sequencing_request_type]
    end

    factory :library_request_type_validator, class: 'RequestType::Validator' do
      request_option { 'library_type' }
      request_type factory: %i[library_creation_request_type]
      valid_options { |rtva| RequestType::Validator::LibraryTypeValidator.new(rtva.request_type.id) }
    end

    factory :pcr_cycles_validator do
      request_option { 'pcr_cycles' }
      default { 0 }
      options { [0] }
    end
  end

  factory :pooling_method, class: 'RequestType::PoolingMethod' do
    pooling_behaviour { 'PlateRow' }
    pooling_options { { pool_count: 8 } }
  end

  factory :library_type do
    sequence(:name) { |i| "Library Type #{i}" }

    factory :library_type_standard do
      name { 'Standard' }
    end
  end

  factory :flowcell_type do
    sequence(:name) { |i| "Flowcell #{i}" }
  end
end
