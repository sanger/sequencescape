##
# A stamp is a means of transfering material from a lot
# into a qcable.

class Stamp < ActiveRecord::Base

  include Uuid::Uuidable
  include ModelExtensions::Stamp

  class StampQcable < ActiveRecord::Base

    set_table_name('stamp_qcables')

    belongs_to :stamp, :inverse_of => :stamp_qcables
    belongs_to :qcable, :inverse_of => :stamp_qcable
    validates_presence_of :stamp, :qcable, :bed, :order

  end

  belongs_to :lot
  belongs_to :robot
  belongs_to :user

  has_many :qcables, :through => :stamp_qcables
  has_many :stamp_qcables, :inverse_of => :stamp, :class_name => 'Stamp::StampQcable'

  validates_presence_of :lot, :user, :robot, :tip_lot

  after_create :stamp!

  private
  def stamp!
    ActiveRecord::Base.transaction do
      qcables.each(&:do_stamp!)
    end
  end
end
