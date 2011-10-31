class RequestQuota < ActiveRecord::Base
  belongs_to :request
  validates_presence_of :request

  belongs_to :quota
  validates_presence_of :quota

  validates_uniqueness_of :quota_id, :scope => :request_id
  validate do |record|
    record.request.request_type_id == record.quota.request_type_id
  end

end
