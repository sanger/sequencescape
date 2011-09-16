class ChangePulldownPlatePurposeNames < ActiveRecord::Migration
  PLATE_PURPOSE_NAME_MAPPINGS = {
    'WGS stock plate'                      => 'WGS stock DNA',
    'WGS fragmentation plate'              => 'WGS Covaris',
    'WGS fragment purification plate'      => 'WGS post-Cov',
    'WGS library preparation plate'        => 'WGS post-Cov-XP',
    'WGS library plate'                    => 'WGS lib',
    'WGS library PCR plate'                => 'WGS lib PCR',
    'WGS amplified library plate'          => 'WGS lib PCR-XP',
    'WGS pooled amplified library plate'   => 'WGS lib pool',

    'SC stock plate'                       => 'SC stock DNA',
    'SC fragmentation plate'               => 'SC Covaris',
    'SC fragment purification plate'       => 'SC post-Cov',
    'SC library preparation plate'         => 'SC post-Cov-XP',
    'SC library plate'                     => 'SC lib',
    'SC library PCR plate'                 => 'SC lib PCR',
    'SC amplified library plate'           => 'SC lib PCR-XP',
    'SC hybridisation plate'               => 'SC hyb',
    'SC captured library plate'            => 'SC cap lib',
    'SC captured library PCR plate'        => 'SC cap lib PCR',
    'SC amplified captured library plate'  => 'SC cap lib PCR-XP',
    'SC pooled captured library plate'     => 'SC cap lib pool',

    'ISC stock plate'                      => 'ISC stock DNA',
    'ISC fragmentation plate'              => 'ISC Covaris',
    'ISC fragment purification plate'      => 'ISC post-Cov',
    'ISC library preparation plate'        => 'ISC post-Cov-XP',
    'ISC library plate'                    => 'ISC lib',
    'ISC library PCR plate'                => 'ISC lib PCR',
    'ISC amplified library plate'          => 'ISC lib PCR-XP',
    'ISC pooled amplified library plate'   => 'ISC lib pool',
    'ISC hybridisation plate'              => 'ISC hyb',
    'ISC captured library plate'           => 'ISC cap lib',
    'ISC captured library PCR plate'       => 'ISC cap lib PCR',
    'ISC amplified captured library plate' => 'ISC cap lib PCR-XP',
    'ISC pooled captured library plate'    => 'ISC cap lib pool'
  }

  def self.update_names(mappings)
    PlatePurpose.transaction do
      mappings.each do |existing, updated|
        purpose = PlatePurpose.find_by_name(existing) or raise StandardError, "Cannot find #{existing.inspect}"
        purpose.update_attributes!(:name => updated)
      end
    end
  end

  def self.up
    update_names(PLATE_PURPOSE_NAME_MAPPINGS)
  end

  def self.down
    update_names(Hash[PLATE_PURPOSE_NAME_MAPPINGS.to_a.map(&:reverse)])
  end
end
