# Included in {BaitLibraryLayout} to provide scopes used by the V1 API
module ModelExtensions::BaitLibraryLayout
  def self.included(base)
    base.class_eval do
      extend ModelExtensions::Plate::NamedScopeHelpers
      include_plate_named_scope :plate
    end
  end
end
