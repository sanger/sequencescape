class CherrypickForFluidgmRequest < CherrypickForPulldownRequest

  has_metadata :as => Request do
    belongs_to :target_purpose, :class_name => 'Purpose'
    association(:target_purpose, :name)
    validates_presence_of :target_purpose
  end


end
