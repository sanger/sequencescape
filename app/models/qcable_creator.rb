#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class QcableCreator < ActiveRecord::Base

  include Uuid::Uuidable

  belongs_to :user
  belongs_to :lot
  has_many :qcables

  validates :user, :presence => true
  validates :lot, :presence => true

  attr_accessor :count

  after_create :make_qcables!

  def make_qcables!
    lot.qcables.build([{:qcable_creator=>self}]*count).tap do |_|
      lot.save!
    end
  end

end
