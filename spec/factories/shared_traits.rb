# frozen_string_literal: true

FactoryBot.define do
  # Automatically add samples to an asset
  trait :with_sample_builder do
    transient do
      sample_count { 0 }
      samples { create_list(:sample, sample_count) }
      aliquot_factory { sample_count > 1 ? :tagged_aliquot : :untagged_aliquot }
    end

    after(:create) do |library_tube, evaluator|
      if evaluator.samples.present?
        library_tube.aliquots =
          evaluator.samples.map { |s| create(evaluator.aliquot_factory, sample: s, library_type: 'Standard') }
      end
    end
  end

  factory :uuid do
    resource factory: %i[labware]
    external_id { SecureRandom.uuid }
  end

  trait :uuidable do
    transient { uuid { SecureRandom.uuid } }

    # Using an after build as I need access to both the transient and the resource.
    after(:build) do |resource, context|
      resource.uuid_object = build :uuid, external_id: context.uuid, resource: resource
    end

    after(:create) { |resource, _context| resource.uuid_object.save! }
  end
end
