module ModelExtensions::Tube

  def self.included(base)
    base.class_eval do
      named_scope :include_purpose, :include => :purpose
    end
  end

end
