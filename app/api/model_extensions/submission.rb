module ModelExtensions::Submission
  def self.included(base)
    base.class_eval do
      named_scope :include_order, :include => { :order => { :study => :uuid_object, :project => :uuid_object, :assets => :uuid_object } }
    end
  end
end
