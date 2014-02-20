##
# A Qcable is an element of a lot which must be approved
# before it may be used.

# require 'qcable/state_machine'

class Qcable < ActiveRecord::Base

  include Uuid::Uuidable
  include AASM
  include Qcable::Statemachine

  belongs_to :lot, :inverse_of => :qcables
  belongs_to :asset
  belongs_to :qcable_creator, :inverse_of => :qcables

  has_one :stamp_qcable, :inverse_of => :qcable, :class_name => 'Stamp::StampQcable'
  has_one :stamp, :through => :stamp_qcable

  validates_presence_of :lot, :asset, :state, :qcable_creator

  before_validation :create_asset!

  delegate :bed, :order, :to => :stamp_qcable, :nil => true

  named_scope :include_for_json, { :include => [:asset,:lot,:stamp,:stamp_qcable] }

  named_scope :stamped, {
    :include => [:stamp_qcable, :stamp],
    :conditions => 'stamp_qcables.id IS NOT NULL',
      :order => 'stamps.created_at ASC, stamp_qcables.order ASC'
  }

  def stamp_index
    return nil if stamp_qcable.nil?
    lot.qcables.stamped.index(self)
  end

  private

  def asset_purpose
    lot.target_purpose
  end

  def create_asset!
    return true if lot.nil?
    self.asset ||= asset_purpose.create!()
  end

end
