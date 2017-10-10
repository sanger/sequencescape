FactoryGirl.define do
  # Automatically add samples to an asset
  trait :with_sample_builder do
    transient do
      sample_count 0
      samples { create_list(:sample, sample_count) }
      aliquot_factory { sample_count > 1 ? :tagged_aliquot : :untagged_aliquot }
    end

    after(:create) do |library_tube, evaluator|
      library_tube.aliquots = evaluator.samples.map do |s|
        create(evaluator.aliquot_factory, sample: s, library_type: 'Standard')
      end
    end
  end
end
