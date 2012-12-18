class CorrectQuotaDiscrepencies < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      each_quota_for(old_request_type) do |old_quota|
        adjust_by(old_quota,old_quota.requests.count)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      each_quota_for(old_request_type) do |old_quota|
        adjust_by(old_quota,-old_quota.requests.count)
      end
    end
  end

  def self.old_request_type
    @ort ||= RequestType.find_by_key('illumina_b_multiplexed_library_creation')
  end

  def self.new_request_type
    @nrt ||= RequestType.find_by_key('illumina_b_std')
  end

  def self.each_quota_for(request_type)
    Quota.find_all_by_request_type_id(request_type.id).each {|q| yield q}
  end

  def self.adjust_by(old_quota,adjustment)
    say "Adjusting #{old_quota.project.name} quotas by #{adjustment}"
    old_quota.update_attributes!(:limit=>(old_quota.limit+adjustment))
    new_quota = Quota.find(:first, :conditions=>{:project_id=> old_quota.project.id, :request_type_id=>new_request_type.id})
    new_quota.update_attributes!(:limit=>(new_quota.limit-adjustment))
  end

end
