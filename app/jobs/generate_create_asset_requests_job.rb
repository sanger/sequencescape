# Generate CreateAssetRequests for the provided assets, linking them to the study.
# Currently used in Tube sample manifests.
# JG: Not entirely sure this is all that useful any more.
GenerateCreateAssetRequestsJob = Struct.new(:asset_ids, :study_id) do
  def perform
    RequestFactory.create_assets_requests(Asset.find(asset_ids), Study.find(study_id))
  end
end
