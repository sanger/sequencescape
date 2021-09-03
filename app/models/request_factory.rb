# frozen_string_literal: true
class RequestFactory # rubocop:todo Style/Documentation
  def self.copy_request(request)
    ActiveRecord::Base.transaction do
      request
        .class
        .create!(request.attributes.except('id', 'created_at', 'updated_at')) do |request_copy|
          request_copy.target_asset_id = nil
          request_copy.state = 'pending'
          request_copy.request_metadata_attributes = request.request_metadata.attributes
          request_copy.created_at = Time.zone.now
        end
    end
  end

  def self.create_assets_requests(assets, study)
    request_type = RequestType.create_asset
    assets.each { |asset| request_type.create!(study: study, asset: asset, state: 'passed') }
  end

  def self.create_external_multiplexed_library_creation_requests(sources, target, study)
    request_type = RequestType.external_multiplexed_library_creation
    sources.each { |asset| request_type.create!(study: study, asset: asset, target_asset: target) }
  end
end
