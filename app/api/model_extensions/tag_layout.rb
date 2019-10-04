# Included in {TagLayout}
# The intent of this file was to provide methods specific to the V1 API
module ModelExtensions::TagLayout
  def self.included(base)
    base.class_eval do
      extend ModelExtensions::Plate::NamedScopeHelpers
      include_plate_named_scope :plate

      scope :include_tag_group, -> { includes(tag_group: :tags, tag2_group: :tags) }
    end
  end
end
