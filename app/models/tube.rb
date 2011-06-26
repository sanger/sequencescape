class Tube < Aliquot::Receptacle
  include LocationAssociation::Locatable
  include Barcode::Barcodeable

  named_scope :include_scanned_into_lab_event, :include => :scanned_into_lab_event
end
