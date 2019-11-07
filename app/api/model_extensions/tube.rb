# Included in {Tube}
# The intent of this file was to provide methods specific to the V1 API
module ModelExtensions::Tube
  def self.included(base)
    base.class_eval do
      scope :include_purpose, -> { includes(:purpose) }
    end
  end
end
