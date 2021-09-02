# frozen_string_literal: true
##
# A stamp is a means of transfering material from a lot
# into a qcable.

class Stamp < ApplicationRecord # rubocop:todo Style/Documentation
  include Uuid::Uuidable
  include ModelExtensions::Stamp

  class StampQcable < ApplicationRecord # rubocop:todo Style/Documentation
    self.table_name = ('stamp_qcables')

    belongs_to :stamp, inverse_of: :stamp_qcables
    belongs_to :qcable, inverse_of: :stamp_qcable
    validates :stamp, presence: true
    validates :qcable, presence: true
    validates :bed, presence: true
    validates :order, presence: true
  end

  belongs_to :lot
  belongs_to :robot
  belongs_to :user

  has_many :stamp_qcables, inverse_of: :stamp, class_name: 'Stamp::StampQcable'
  has_many :qcables, through: :stamp_qcables

  validates :lot, presence: true
  validates :user, presence: true
  validates :robot, presence: true
  validates :tip_lot, presence: true

  after_create :stamp!

  private

  def stamp!
    ActiveRecord::Base.transaction { qcables.each(&:do_stamp!) }
  end
end
