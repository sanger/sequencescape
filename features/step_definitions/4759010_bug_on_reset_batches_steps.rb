Given /^sequencescape is setup for 4759010$/ do
  # Number of tags here needs to be the same as the number of requests below.
  group = Factory(:tag_group, :name => 'Tag group for 4759010')
  (1..10).each { |i| group.tags.create!(:map_id => i, :oligo => 'Tag for 4759010') }
end

Given /^a batch in "Cluster formation PE" has been setup for feature 4759010$/ do
  pending
end

Given /^a batch in "Illumina-B MX Library Preparation" has been setup for feature 4759010$/ do
  pipeline    = Pipeline.find_by_name("Illumina-B MX Library Preparation") or raise StandardError, "Cannot find pipeline 'Illumina-B MX Library Preparation'"
  batch       = Factory :batch, :pipeline => pipeline, :state => :started
  asset_group = Factory(:asset_group)

  submission = Factory::submission(
    :asset_group   => asset_group,
    :request_options => {
      :read_length => 76,
      :fragment_size_required_from => 1,
      :fragment_size_required_to => 20,
      :library_type => 'Standard'
    },
    :request_types => [
      RequestType.find_by_key('illumina_b_multiplexed_library_creation'),
      RequestType.find_by_key('paired_end_sequencing')
    ].map(&:id)
  )

  asset_type = pipeline_name_to_asset_type(pipeline.name)

  10.times do |_|
    # Ensure that the source and destination assets are setup correctly
    source      = Factory(pipeline.request_types.last.asset_type.underscore, :location => pipeline.location)
    destination = Factory("empty_#{pipeline.asset_type.underscore}")

    request  = Factory :request, :request_type => pipeline.request_types.last, :submission_id => submission.id, :asset => source, :target_asset => destination

    batch.requests << request
    asset_group.assets << source
  end


  pipeline = Pipeline.find_by_name("Cluster formation PE") or raise StandardError, "Cannot find pipeline '#{ name }'"

  request  = Factory :request, :request_type => pipeline.request_types.last, :submission_id => submission.id, :asset => Factory(asset_type)
  request.asset.location    = pipeline.location
  request.asset.save!
  batch.requests << request
  asset_group.assets << request.asset
end

When /^I select all requests$/ do
 page.all('.request_checkbox').each { |checkbox| checkbox.set(true) }
end
