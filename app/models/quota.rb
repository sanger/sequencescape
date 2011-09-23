class Quota < ActiveRecord::Base
  include Api::QuotaIO::Extensions
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable

  belongs_to :project
  belongs_to :request_type
  has_many :request_quotas
  has_many :requests, :through => :request_quotas

  acts_as_audited :on => [:destroy, :update]

  named_scope :request_type, lambda {|*args| {:conditions => { :request_type_id => args[0]} } }

  def used
    self.request_quotas.count + self.preordered_count
  end

  def remaining
    used - limit
  end

  def update_limit_to__used!
    limit = used
    save!
  end


  # this used by order to increase the amount of used quota before
  # actually creating the request
  # The booking is released when the request is effectively associated to the quota
  def book_request!(number)
    self.preordered_count+=number
    save!
  end

  def unbook_request!(number)
    self.preordered_count-=[number, preordered_count].min
    save!
  end

  def add_request!(request, unbook=false)
    #TODO[mb14] validate enough quota remaining here
    #but we don't want to break old behavior yet.
    requests << request
    unbook_request!(1) if unbook
    save!
  end

end


