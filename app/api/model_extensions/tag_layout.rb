module ModelExtensions::TagLayout
  def self.included(base)
    base.class_eval do
      extend ModelExtensions::Plate::NamedScopeHelpers
      include_plate_named_scope :plate

      named_scope :include_tag_group, { :include => { :tag_group => :tags } }
    end
  end
end
