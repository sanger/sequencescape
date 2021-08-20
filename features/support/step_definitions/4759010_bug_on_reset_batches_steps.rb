# frozen_string_literal: true

Given /^sequencescape is setup for 4759010$/ do
  # Number of tags here needs to be the same as the number of requests below.
  group = FactoryBot.create(:tag_group, name: 'Tag group for 4759010', tag_count: 10)
end

Given /^a batch in "Illumina-B MX Library Preparation" has been setup for feature 4759010$/ do
  pipeline = Pipeline.find_by(name: 'Illumina-B MX Library Preparation') or
    raise StandardError, "Cannot find pipeline 'Illumina-B MX Library Preparation'"
  batch = FactoryBot.create :batch, pipeline: pipeline, state: 'pending'
  asset_group = FactoryBot.create(:asset_group)

  submission =
    FactoryHelp.submission(
      asset_group: asset_group,
      request_options: {
        read_length: 76,
        fragment_size_required_from: 1,
        fragment_size_required_to: 20,
        library_type: 'Standard'
      },
      request_types:
        [
          RequestType.find_by(key: 'illumina_b_multiplexed_library_creation'),
          RequestType.find_by(key: 'paired_end_sequencing')
        ].map(&:id)
    )

  asset_type = pipeline_name_to_asset_type(pipeline.name)

  10.times do |_|
    # Ensure that the source and destination assets are setup correctly
    source = FactoryBot.create(pipeline.request_types.last.asset_type.underscore)
    destination = FactoryBot.create("empty_#{pipeline.asset_type.underscore}")

    request =
      FactoryBot.create :multiplexed_library_creation_request,
                        request_type: RequestType.find_by(key: 'illumina_b_multiplexed_library_creation'),
                        submission_id: submission.id,
                        asset: source,
                        target_asset: destination

    batch.requests << request
    asset_group.assets << source.receptacle
  end

  pipeline = Pipeline.find_by(name: 'Cluster formation PE') or raise StandardError, "Cannot find pipeline '#{name}'"

  request =
    FactoryBot.create :sequencing_request,
                      request_type: pipeline.request_types.last,
                      submission_id: submission.id,
                      asset: FactoryBot.create(asset_type)
  request.asset.save!

  # batch.requests << request
  asset_group.assets << request.asset
end
