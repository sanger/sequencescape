FactoryGirl.define do
  trait :library_request_validators do
    after(:build) { |request_type|
      request_type.library_types_request_types << create(:library_types_request_type, request_type: request_type)
      request_type.request_type_validators << create(:library_request_type_validator, request_type: request_type)
    }
  end

  factory :request_type do
    name           { generate :request_type_name }
    key            { generate :request_type_key }
    deprecated     false
    asset_type     'SampleTube'
    request_class  Request
    order          1
    workflow { |workflow| workflow.association(:submission_workflow) }
    initial_state 'pending'
    request_purpose

    factory :well_request_type do
      asset_type 'Well'
      request_class CustomerRequest

      factory :library_request_type do
        request_class IlluminaHtp::Requests::StdLibraryRequest
        billable true
        library_request_validators
      end

      factory :multiplex_request_type do
        request_class Request::Multiplexing
        billable false
        for_multiplexing true
        association(:target_purpose, factory: :tube_purpose)
      end
    end

    factory :library_creation_request_type do
      target_asset_type 'LibraryTube'
      request_class LibraryCreationRequest

      after(:build) { |request_type|
        request_type.library_types_request_types << create(:library_types_request_type, request_type: request_type)
        request_type.request_type_validators << create(:library_request_type_validator, request_type: request_type)
      }
    end

    factory :sequencing_request_type do
      asset_type     'LibraryTube'
      request_class  SequencingRequest

      after(:build) { |request_type|
        request_type.request_type_validators << create(:sequencing_request_type_validator, request_type: request_type)
      }
    end

    factory :multiplexed_library_creation_request_type do
      request_class      MultiplexedLibraryCreationRequest
      asset_type         'SampleTube'
      for_multiplexing   true

      after(:build) do |request_type|
        request_type.library_types_request_types << create(:library_types_request_type, request_type: request_type)
        request_type.request_type_validators << create(:library_request_type_validator, request_type: request_type)
      end
    end

    factory :plate_based_multiplexed_library_creation_request_type do
      request_class      MultiplexedLibraryCreationRequest
      asset_type         'Well'
      for_multiplexing   true

      after(:build) do |request_type|
        request_type.library_types_request_types << create(:library_types_request_type, request_type: request_type)
        request_type.request_type_validators << create(:library_request_type_validator, request_type: request_type)
      end
    end

    factory :validated_request_type do
      after(:create) do |request_type|
        request_type.extended_validators << create(:extended_validator)
      end
    end

    factory :transfer_request_type do
      request_class TransferRequest
      name 'Transfer'
      key 'transfer'
      asset_type 'Asset'
    end
  end

  factory :library_types_request_type do
    library_type
    is_default true
  end

  factory :sequencing_request_type_validator, class: RequestType::Validator do
    request_option 'read_length'
    valid_options { RequestType::Validator::ArrayWithDefault.new([37, 54, 76, 108], 54) }
  end

  factory :library_request_type_validator, class: RequestType::Validator do
    request_option 'library_type'
    valid_options { |rtva| RequestType::Validator::LibraryTypeValidator.new(rtva.request_type.id) }
  end
end
