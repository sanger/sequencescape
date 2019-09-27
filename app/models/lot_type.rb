# frozen_string_literal: true

# A {LotType} governs the behaviour of a {Lot}
# It is selected when generating a Lot in Gatekeeper
class LotType < ApplicationRecord
  include Uuid::Uuidable

  has_many :lots, inverse_of: :lot_type
  belongs_to :target_purpose, class_name: 'Purpose'

  validates :name, :template_class, presence: true
  validates :name, uniqueness: { case_sensitive: false }

  def valid_template_class
    template_class.constantize
  end

  delegate :create!, to: :lots

  def printer_type
    target_purpose.barcode_printer_type.name
  end
end
