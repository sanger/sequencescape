##
# A lot represents a received batch of consumables (eg. tag plates)
# that can be assumed to share some level of QC.

class Lot < ActiveRecord::Base

  include Uuid::Uuidable

  belongs_to :lot_type
  belongs_to :user
  belongs_to :template, :polymorphic => true

  has_many :qcables, :inverse_of => :lot do

    def create!(opts)
      construct(opts)
      proxy_owner.save!
    end

    private
    def construct(opts)
      count = opts.delete(:count)||1
      proxy_owner.qcables.build([opts]*count)
    end

  end

  validates_presence_of :lot_number, :lot_type, :user, :template, :recieved_at
  validates_uniqueness_of :lot_number, :scope => :lot_type_id

  validate :valid_template?

  delegate :valid_template_class, :target_purpose, :to => :lot_type

  private

  def valid_template?
    return false unless lot_type.present?
    return true if template.is_a?(valid_template_class)
    errors.add(:template,'is not an appropriate type for this lot')
    false
  end

end
