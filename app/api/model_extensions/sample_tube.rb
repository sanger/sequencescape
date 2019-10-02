# Included in {SampleTube}
# The intent of this file was to provide methods specific to the V1 API
# @todo Rails relationships should be moved to SampleTube
module ModelExtensions::SampleTube
  def self.included(base)
    base.class_eval do
      has_many :library_tubes, through: :links_as_parent, source: :descendant, validate: false
    end
  end
end
