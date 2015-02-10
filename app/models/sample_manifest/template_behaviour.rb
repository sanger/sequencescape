#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
module SampleManifest::TemplateBehaviour
  def applicable_templates
    return SampleManifestTemplate.all unless self.asset_type.present?
    SampleManifestTemplate.all(:conditions => [ 'asset_type=? OR asset_type IS NULL', asset_type ], :order => 'asset_type DESC')
  end
end
