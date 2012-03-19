module Pipeline::InboxUngrouped
  def self.included(base)
    base.has_many :inbox, :class_name => 'Request', :extend => Pipeline::RequestsInStorage
  end

  # Never group by submission
  def group_by_submission?
    false
  end
end
