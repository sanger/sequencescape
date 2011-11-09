module Pipeline::InboxUngrouped
  def self.included(base)
    base.has_many :inbox, :through => :request_type, :source => :requests, :extend => Pipeline::RequestsInStorage
  end

  # Never group by submission
  def group_by_submission?
    false
  end
end
