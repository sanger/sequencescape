# frozen_string_literal: true

FactoryBot.define do
  factory :batch do
    item_limit { 4 }
    user
    pipeline
    state { 'pending' }
    qc_pipeline_id { '' }
    qc_state { 'qc_pending' }
    assignee_id { |user| user.association(:user) }
    production_state { nil }

    transient do
      request_attributes { Array.new(request_count) { {} } }
      request_count { 0 }
      request_factory { :request }
      batch_request_factory { :batch_request }
    end

    after(:build) do |batch, evaluator|
      request_type = batch.pipeline.request_types.first
      if evaluator.request_attributes.present?
        batch.requests =
          evaluator.request_attributes.map do |request_attribute|
            build(evaluator.request_factory, request_attribute.reverse_merge(request_type:))
          end
      end
    end

    factory :multiplexed_batch do
      pipeline factory: %i[multiplexed_pipeline]
    end

    factory :sequencing_batch do
      pipeline factory: %i[sequencing_pipeline]
    end

    factory :ultima_sequencing_batch do
      pipeline factory: %i[ultima_sequencing_pipeline]
    end

    factory :cherrypick_batch do
      transient do
        request_count { 1 } # We create one request by default as cherrypick pipelines have a minimum batch size
        batch_request_factory { :cherrypick_batch_request }
        request_factory { :cherrypick_request }
      end
      pipeline factory: %i[cherrypick_pipeline]
    end

    factory :ultima_sequencing_batch do
      pipeline factory: %i[ultima_sequencing_pipeline]
    end
  end

  factory :pac_bio_sequencing_batch, class: 'Batch' do
    transient do
      target_plate { create(:plate_with_tagged_wells, sample_count: request_count) }
      request_count { 0 }
      assets { create_list(:pac_bio_library_tube, request_count) }
    end

    pipeline factory: %i[pac_bio_sequencing_pipeline]

    after(:build) do |batch, evaluator|
      evaluator.assets.each_with_index.each do |asset, index|
        create(
          :pac_bio_sequencing_request,
          asset: asset,
          target_asset: evaluator.target_plate.wells[index],
          request_type: batch.pipeline.request_types.first,
          batch: batch
        )
      end
    end
  end
end
