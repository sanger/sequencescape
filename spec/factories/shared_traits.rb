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
        library_tube.aliquots = evaluator.samples.map do |s|
          create(evaluator.aliquot_factory, sample: s, library_type: 'Standard')
        end
      end
    end
  end

  factory :uuid do
    association(:resource, factory: :labware)
    external_id { SecureRandom.uuid }
  end

  trait :uuidable do
    transient do
      uuid { SecureRandom.uuid }
    end

    # Using an after build as I need access to both the transient and the resource.
    after(:build) do |resource, context|
      resource.uuid_object = build :uuid, external_id: context.uuid, resource: resource
    end

    after(:create) do |resource, _context|
      resource.uuid_object.save!
    end
  end
end
