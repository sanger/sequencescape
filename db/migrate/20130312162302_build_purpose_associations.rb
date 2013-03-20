class BuildPurposeAssociations < ActiveRecord::Migration
  def self.up
    prune(IlluminaB::PlatePurposes::BRANCHES).each do |branch|
      IlluminaB::PlatePurposes.create_branch(branch)
    end
  end

  def self.down
    prune(IlluminaB::PlatePurposes::BRANCHES).each do |branch|
      #
    end
  end

  def self.prune(branches)
    branches.reject{|branch| existing_branches.include?(branch)}
  end

  def self.existing_branches
    [
      [ 'ILB_STD_INPUT', 'ILB_STD_COVARIS', 'ILB_STD_SH', 'ILB_STD_PREPCR', 'ILB_STD_PCR', 'ILB_STD_PCRXP', 'ILB_STD_STOCK', 'ILB_STD_MX' ],
      [ 'ILB_STD_PREPCR', 'ILB_STD_PCRR', 'ILB_STD_PCRRXP' ]
    ]
  end

end
