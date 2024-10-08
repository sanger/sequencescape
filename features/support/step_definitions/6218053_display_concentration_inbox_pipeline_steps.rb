# frozen_string_literal: true

Given /^Pipeline "([^"]*)" and a setup for 6218053$/ do |name|
  pipeline = Pipeline.find_by(name:) or raise StandardError, "Cannot find pipeline '#{name}'"
  asset_type = pipeline_name_to_asset_type(name)
  request_type = pipeline.request_types.detect { |rt| !rt.deprecated }
  metadata = FactoryBot.create :"request_metadata_for_#{request_type.key}"
  request =
    FactoryBot.create :request_with_submission,
                      request_type: request_type,
                      asset: FactoryBot.create(asset_type),
                      request_metadata: metadata
  request.asset.save!
end
