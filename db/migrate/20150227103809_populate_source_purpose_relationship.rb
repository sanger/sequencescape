#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class PopulateSourcePurposeRelationship < ActiveRecord::Migration

  def self.up
    ActiveRecord::Base.transaction do
      Purpose.find_each do |purpose|
        purpose.source_purpose_id = Purpose.find_by_name(source_for(purpose)).try(:id)
        purpose.save!
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Purpose.find_each do |purpose|
        purpose.source_purpose_id = nil if source_for(purpose).present?
        purose.save!
      end
    end
  end

  def self.source_for(purpose)
    (config.detect {|k,v| v.include?(purpose.name) }||[]).first
  end

  def self.config
    @cf||={
      'Cherrypicked' => [
        'Cherrypicked',
        'Shear',
        'Post Shear',
        'AL Libs',
        'Lib PCR',
        'Lib PCRR',
        'Lib PCR-XP',
        'Lib PCRR-XP',
        'Post Shear XP',
        'Lib Norm',
        'Lib Norm 2',
        'Lib Norm 2 Pool',
        'Lib Pool',
        'Lib Pool Norm',
        'Lib Pool Pippin',
        'Lib Pool Conc',
        'Lib Pool SS',
        'Lib Pool SS-XP',
        'Lib Pool SS-XP-Norm',
        'Cap Lib Pool Norm',
        'Lib PCR-XP QC',
        'Lib Norm QC'
      ],
      'ILB_STD_INPUT' => [
        'ILB_STD_INPUT',
        'ILB_STD_COVARIS',
        'ILB_STD_SH',
        'ILB_STD_PREPCR',
        'ILB_STD_PCR',
        'ILB_STD_PCRR',
        'ILB_STD_PCRXP',
        'ILB_STD_PCRRXP',
        'ILB_STD_STOCK',
        'ILB_STD_MX'
      ],
      'ISCH lib pool' => [
        'ISCH lib pool',
        'ISCH hyb',
        'ISCH cap lib',
        'ISCH cap lib PCR',
        'ISCH cap lib PCR-XP',
        'ISCH cap lib pool'
      ],
      'WGS stock DNA' => [
        'WGS stock DNA',
        'WGS Covaris',
        'WGS post-Cov',
        'WGS post-Cov-XP',
        'WGS lib',
        'WGS lib PCR',
        'WGS lib PCR-XP',
        'WGS lib pool'
      ],
      'SC stock DNA' => [
        'SC stock DNA',
        'SC Covaris',
        'SC post-Cov',
        'SC post-Cov-XP',
        'SC lib',
        'SC lib PCR',
        'SC lib PCR-XP',
        'SC hyb',
        'SC cap lib',
        'SC cap lib PCR',
        'SC cap lib PCR-XP',
        'SC cap lib pool'
      ],
      'ISC stock DNA' => [
        'ISC stock DNA',
        'ISC Covaris',
        'ISC post-Cov',
        'ISC post-Cov-XP',
        'ISC lib',
        'ISC lib PCR',
        'ISC lib PCR-XP',
        'ISC lib pool',
        'ISC hyb',
        'ISC cap lib',
        'ISC cap lib PCR',
        'ISC cap lib PCR-XP',
        'ISC cap lib pool'
      ]
    }
  end
end
