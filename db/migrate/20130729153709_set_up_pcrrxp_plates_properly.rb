class SetUpPcrrxpPlatesProperly < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IlluminaB::PlatePurposes.create_branch(['ILB_STD_PCRRXP', 'ILB_STD_STOCK'])
      IlluminaHtp::PlatePurposes.create_branch(['Lib PCRR-XP','Lib Pool Pippin' ])
      IlluminaHtp::PlatePurposes.create_branch([ 'Lib PCRR-XP','ISC lib pool' ])
    end
  end

  def self.down
    PlatePurpose.find_by_name('ILB_STD_PCRRXP').child_relationships.detect{|r| r.child_purpose.name=='ILB_STD_STOCK'}.destroy
    PlatePurpose.find_by_name('Lib PCRR-XP').child_relationships.detect{|r| r.child_purpose.name=='Lib Pool Pippin'}.destroy
    PlatePurpose.find_by_name('Lib PCRR-XP').child_relationships.detect{|r| r.child_purpose.name=='ISC lib pool'}.destroy
  end
end
