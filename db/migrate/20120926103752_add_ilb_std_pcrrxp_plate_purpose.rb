class AddIlbStdPcrrxpPlatePurpose < ActiveRecord::Migration
  class Purpose < ActiveRecord::Base
    class Relationship < ActiveRecord::Base
      set_table_name('plate_purpose_relationships')
      belongs_to :child, :class_name => 'AddIlbStdPcrrxpPlatePurpose::Purpose'
      belongs_to :transfer_request_type, :class_name => 'AddIlbStdPcrrxpPlatePurpose::RequestType'

      named_scope :with_child,  lambda { |plate_purpose| { :conditions => { :child_id  => plate_purpose.id } } }
    end

    set_table_name('plate_purposes')
    set_inheritance_column(nil)

    has_many :child_relationships, :class_name => 'AddIlbStdPcrrxpPlatePurpose::Purpose::Relationship', :foreign_key => :parent_id, :dependent => :destroy
  end

  class RequestType < ActiveRecord::Base
    set_table_name('request_types')
    set_inheritance_column(nil)
  end

  def self.up
    ActiveRecord::Base.transaction do
      pcr_xp   = Purpose.find_by_name('ILB_STD_PCRXP') or raise "Cannot find ILB_STD_PCRXP"
      pcr_r_xp = pcr_xp.clone.tap { |p| p.name = 'ILB_STD_PCRRXP' ; p.save! }

      # Ensure the child transfers are correctly setup
      pcr_xp.child_relationships.each do |relationship|
        request_type = relationship.transfer_request_type.clone.tap do |r|
          r.name = r.name.sub(pcr_xp.name, pcr_r_xp.name)
          r.key  = r.name.gsub(/\W+/, '_')
          r.save!
        end
        pcr_r_xp.child_relationships.create!(:child => relationship.child, :transfer_request_type => request_type)
      end

      # Ensure that the PCR-R plate goes into the appropriate type
      pcr_r = Purpose.find_by_name('ILB_STD_PCRR') or raise "Cannot find ILB_STD_PCRR"
      pcr_r.child_relationships.with_child(pcr_xp).all.each do |relationship|
        relationship.child = pcr_r_xp
        relationship.save!
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      pcr_xp   = Purpose.find_by_name('ILB_STD_PCRXP')  or raise "Cannot find ILB_STD_PCRXP"
      pcr_r_xp = Purpose.find_by_name('ILB_STD_PCRRXP') or raise "Cannot find ILB_STD_PCRRXP"
      pcr_r    = Purpose.find_by_name('ILB_STD_PCRR')   or raise "Cannot find ILB_STD_PCRR"

      pcr_r.child_relationships.with_child(pcr_r_xp).all.each do |relationship|
        relationship.child = pcr_xp
        relationship.save!
      end

      pcr_r_xp.destroy
    end
  end
end
