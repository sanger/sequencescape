module SampleManifest::TemplateBehaviour
  def applicable_templates
    return SampleManifestTemplate.all unless self.asset_type.present?
    SampleManifestTemplate.all(:conditions => [ 'asset_type=? OR asset_type IS NULL', asset_type ], :order => 'asset_type DESC')
  end
end
