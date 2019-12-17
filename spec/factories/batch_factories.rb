# frozen_string_literal: true

FactoryBot.define do
  factory :batch do
    item_limit { 4 }
    user
    pipeline
    state                 { 'pending' }
    qc_pipeline_id        { '' }
    qc_state              { 'qc_pending' }
    assignee_id           { |user| user.association(:user) }
    production_state      { nil }

    transient do
      request_count { 0 }
      batch_request_factory { :batch_request }
    end

    after(:build) do |batch, evaluator|
      if evaluator.request_count.positive?
        batch.batch_requests = build_list(evaluator.batch_request_factory,
                                          evaluator.request_count,
                                          batch: batch)
      end
    end

    factory :multiplexed_batch do
      association(:pipeline, factory: :multiplexed_pipeline)
    end

    factory :sequencing_batch do
      association(:pipeline, factory: :sequencing_pipeline)
    end
  end

  factory :pac_bio_sequencing_batch, class: 'Batch' do
    transient do
      target_plate { create(:plate_with_tagged_wells, sample_count: request_count) }
      request_count { 0 }
      assets { create_list(:pac_bio_library_tube, request_count) }
    end

    association(:pipeline, factory: :pac_bio_sequencing_pipeline)

    after(:build) do |batch, evaluator|
      evaluator.assets.each_with_index.map do |asset, index|
        create :pac_bio_sequencing_request,
               asset: asset,
               target_asset: evaluator.target_plate.wells[index],
               request_type: batch.pipeline.request_types.first,
               batch: batch
      end
    end
  end
end
