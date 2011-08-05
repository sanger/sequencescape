# TODO: All of the behaviour in this file should really exist within the PlateCreation model.
module ModelExtensions::PlateCreation
  def self.included(base)
    base.class_eval do
      extend ModelExtensions::Plate::NamedScopeHelpers

      include_plate_named_scope :parent
      include_plate_named_scope :child
    end
  end
end
