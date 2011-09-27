class Quota < ActiveRecord::Base
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

  acts_as_audited :on => [:destroy, :update]

  named_scope :request_type, lambda {|*args| {:conditions => { :request_type_id => args[0]} } }

  def used
    self.request_quotas.count + self.preordered_count
  end

  def remaining
    limit - used
  end

  def update_limit_to__used!
    limit = used
    save!
  end


  # this used by order to increase the amount of used quota before
  # actually creating the request
  # The booking is released when the request is effectively associated to the quota
  def book_request!(number, check_quota)
    return if number == 0
    check_enough_quota_for!(number)  if check_quota
    self.preordered_count+=number
    save!
  end

  def check_enough_quota_for!(number)
      raise QuotaException, "Insufficient quota for #{request_type.name}"  if remaining < number
  end
  private :check_enough_quota_for!

  def unbook_request!(number)
    self.preordered_count-=[number, preordered_count].min
    save!
  end

  def add_request!(request, unbook=false, check_quota=true)
    #TODO[mb14] validate enough quota remaining here
    #but we don't want to break old behavior yet.
    #even though the quota knows it project and could ask if enforce quota , we
    #let the caller decide if check or not
    return if self.request_ids.include?(request.id) or !request.quota_counted?
    Quota.transaction do 
      unbook_request!(1) if unbook
      check_enough_quota_for!(number)  if check_quota
      requests << request
      save!
    end
  end

end


