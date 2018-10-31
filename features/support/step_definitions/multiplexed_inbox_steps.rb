Given(/^that there is a "([^"]*)" pipeline$/) do |pipeline_name|
  @pipeline = Pipeline.find_by(name: pipeline_name)
end

Given(/^that there are (\d+) requests in that pipeline$/) do |number_requests|
  asset_type = pipeline_name_to_asset_type(@pipeline.name)
  number_requests.to_i.times do
    request = FactoryBot.create(
      :request_with_submission,
      request_type: @pipeline.request_types.last,
      asset: FactoryBot.create(asset_type)
    )

    request.asset.save!
  end
end

Then(/^we see the requests in the inbox$/) do
  with_scope('#pipeline_inbox') do
    @pipeline.requests.map(&:asset).map(&:name).each do |asset_name|
      assert page.has_content?(asset_name)
    end
  end
end
