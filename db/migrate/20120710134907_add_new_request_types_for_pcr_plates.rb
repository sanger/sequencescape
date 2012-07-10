class AddNewRequestTypesForPcrPlates < ActiveRecord::Migration
  def self.up
    attach_request_type do |parent, child, request_class|
      request_type_name = "Illumina-B #{parent}-#{child}"
      RequestType.create!(:name => request_type_name, :key => request_type_name.gsub(/\W+/, '_'), :request_class_name => request_class, :asset_type => 'Well', :order => 1)
    end
  end

  def self.down
    attach_request_type do |*args|
      RequestType.transfer
    end
  end

  def self.attach_request_type(&block)
    ActiveRecord::Base.transaction do
      IlluminaB::PlatePurposes::PLATE_PURPOSES_TO_REQUEST_CLASS_NAMES.each do |parent, child, request_class|
        parent_purpose = PlatePurpose.find_by_name(parent) or raise "Cannot find parent plate purpose #{parent.inspect}"
        child_purpose  = PlatePurpose.find_by_name(child)  or raise "Cannot find child plate purpose #{child.inspect}"

        parent_purpose.child_relationships.with_child(child_purpose).first.update_attributes!(:transfer_request_type => yield(parent, child, request_class))
      end
    end
  end
end
