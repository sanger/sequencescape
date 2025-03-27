# frozen_string_literal: true
# Creating an instance of this class causes a child plate, with the specified plate type, to be created from
# the parent.
class PlateCreation < AssetCreation
  module CreationChild
    def self.included(base)
      base.class_eval { has_many :plate_creations, foreign_key: :child_id }
    end
  end

  module Children
    def self.included(base)
      base.class_eval do
        include_plate_named_scope :child
        belongs_to :child, class_name: 'Plate'

        validates_unassigned(:child)
      end
    end

    private

    def target_for_ownership
      child
    end

    def children
      [child]
    end

    def create_children!
      self.child = child_purpose.create!(sanger_barcode:)
    end
  end

  include_plate_named_scope :parent
  include Children

  # This is the child that is created from the parent.  It cannot be assigned before validation.
  belongs_to :parent, class_name: 'Plate'
  attr_accessor :sanger_barcode
  attr_accessor :register_stock

  private

  def record_creation_of_children
    parent.events.create_plate!(child_purpose, child, user)
    register_stock_for_plate if register_stock
  end

  def register_stock_for_plate
    return if child.blank?
    child.wells.each(&:register_stock!)
  end
end
