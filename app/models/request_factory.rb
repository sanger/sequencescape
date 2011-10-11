class RequestFactory
  def self.copy_request(request)
    ActiveRecord::Base.transaction do
      raise Quota::Error.new, "Insufficient quota for #{request.request_type.name}" unless request.has_quota?(1)

      request.class.create!(request.attributes) do |request_copy|
        request_copy.target_asset_id = nil
        request_copy.state           = "pending"
        request_copy.create_request_metadata(request.request_metadata.attributes)
        request_copy.created_at      = Time.now

        request.quotas.each do |q|
          q.add_request!(request_copy, false, q.project.enforce_quotas?)
        end
      end
    end
  end

  # NOTE: This must remain as taking Asset ID and Study ID values, and not be converted to Assets and Study objects, because
  # delayed job does not work with actual ActiveRecord objects.
  def self.create_assets_requests(asset_ids, study_id)
    raise StandardError, "Can only accept asset IDs" unless asset_ids.all? { |i| i.is_a?(Fixnum) or i.is_a?(String) }
    raise StandardError, "Can only accept study ID" unless study_id.is_a?(Fixnum) or study_id.is_a?(String)

    # internal requests to link study -> request -> asset -> sample
    # TODO: do this as a submission
    request_type = RequestType.find_by_key('create_asset') or raise StandardError, "Cannot find create asset request type"
    requests = asset_ids.map { |asset_id| request_type.new(:study_id => study_id, :asset_id => asset_id, :state => 'passed') }
    Request.import requests
  end
end
