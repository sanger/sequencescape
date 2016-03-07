#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
##
# A stamp is a means of transfering material from a lot
# into a qcable.

class Stamp < ActiveRecord::Base

  include Uuid::Uuidable
  include ModelExtensions::Stamp

  class StampQcable < ActiveRecord::Base

    self.table_name =('stamp_qcables')

    belongs_to :stamp, :inverse_of => :stamp_qcables
    belongs_to :qcable, :inverse_of => :stamp_qcable
    validates :stamp, :presence => true
    validates :qcable,  :presence => true
    validates :bed,  :presence => true
    validates :order, :presence => true

  end

  belongs_to :lot
  belongs_to :robot
  belongs_to :user

  has_many :qcables, :through => :stamp_qcables
  has_many :stamp_qcables, :inverse_of => :stamp, :class_name => 'Stamp::StampQcable'

  validates :lot, :presence => true
  validates :user, :presence => true
  validates :robot, :presence => true
  validates :tip_lot, :presence => true

  after_create :stamp!

  private
  def stamp!
    ActiveRecord::Base.transaction do
      qcables.each(&:do_stamp!)
    end
  end
end
