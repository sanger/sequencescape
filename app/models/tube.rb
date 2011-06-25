class Tube < Aliquot::Receptacle
  include LocationAssociation::Locatable

  named_scope :include_scanned_into_lab_event, :include => :scanned_into_lab_event
end
