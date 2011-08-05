module ModelExtensions::SampleTube
  def self.included(base)
    base.class_eval do
      has_many :library_tubes, :through => :links_as_parent, :source => :descendant
    end
  end
end
