##
# A lot represents a received batch of consumables (eg. tag plates)
# that can be assumed to share some level of QC.

class Lot < ActiveRecord::Base

  module Template
    def self.included(base)
      base.class_eval do
        belongs_to :lot
      end
    end
  end

  # include Api::LotIO::Extensions
  include Uuid::Uuidable

  belongs_to :lot_type
  belongs_to :user
  belongs_to :template, :polymorphic => true

  has_many :qcables, :inverse_of => :lot

  has_many :stamps, :inverse_of => :lot

  validates_presence_of :lot_number, :lot_type, :user, :template, :received_at
  validates_uniqueness_of :lot_number, :scope => :lot_type_id

  validate :valid_template?

  delegate :valid_template_class, :target_purpose, :to => :lot_type

  named_scope :include_lot_type, { :include => :lot_type }
  named_scope :include_template, { :include => :template }

  private

  def valid_template?
    return false unless lot_type.present?
    return true if template.is_a?(valid_template_class)
    errors.add(:template,'is not an appropriate type for this lot')
    false
  end

end
