class Quota < ActiveRecord::Base
  Error = Class.new(Exception)

  include Api::QuotaIO::Extensions
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable

  belongs_to :project
  belongs_to :request_type
  has_many :request_quotas
  has_many :requests, :through => :request_quotas

  validates_presence_of :request_type
  validates_uniqueness_of :request_type_id, :scope => :project_id



  named_scope :request_type, lambda {|*args| {:conditions => { :request_type_id => args[0]} } }
  named_scope :counted_, lambda {|*args| {:conditions => { :request_type_id => args[0]} } }

  def used
    self.requests.quota_counted.count + self.preordered_count
  end

  def remaining
    [limit - used, 0].max
  end

  def update_limit_to__used!
    limit = used
    save!
  end


  # this used by order to increase the amount of used quota before
  # actually creating the request
  # The booking is released when the request is effectively associated to the quota
  def book_request!(number, check_quota)
    logger.warn "Book #{self.inspect} #{number}"
    return if number == 0
    check_enough_quota_for!(number)  if check_quota
    # We need increment to be atomic to not interfere with other rails instance
    Quota.update_counters self, :preordered_count => number
    reload
  end

  def check_enough_quota_for!(number)
    lock!
    raise Quota::Error, "Insufficient quota for #{request_type.name} (require #{number} but only #{remaining} remaining)"  if number > remaining
  end
  private :check_enough_quota_for!

  def unbook_request!(number)
    logger.warn "Unbook #{self.inspect} #{number}"
    Quota.update_counters self, :preordered_count => -number
    reload
  end

  def add_request!(request, unbook=false, check_quota=true)
    #TODO[mb14] validate enough quota remaining here
    #but we don't want to break old behavior yet.
    #even though the quota knows it project and could ask if enforce quota , we
    #let the caller decide if check or not
    return if self.request_ids.include?(request.id) or !request.quota_counted?
    Quota.transaction do
      lock! # we lock until the end of the transactio
      unbook_request!(1) if unbook
      check_enough_quota_for!(1)  if check_quota
      requests << request
      save!
    end
  end

end


