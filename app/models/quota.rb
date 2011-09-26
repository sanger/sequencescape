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
  def book_request!(number)
    return if number == 0
    self.preordered_count+=number
    save!
  end

  def unbook_request!(number)
    self.preordered_count-=[number, preordered_count].min
    save!
  end

  def add_request!(request, unbook=false, check_quota=true)
    #TODO[mb14] validate enough quota remaining here
    #but we don't want to break old behavior yet.
    return if self.request_ids.include?(request.id) or !request.quota_counted?
    Quota.transaction do 
      unbook_request!(1) if unbook
      raise QuotaException, "Insuficcient quota of request type #{request_type}"  if check_quota && remaining <= 0
      requests << request
      save!
    end
  end

end


