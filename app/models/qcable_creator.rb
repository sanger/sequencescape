class QcableCreator < ActiveRecord::Base

  include Uuid::Uuidable

  belongs_to :user
  belongs_to :lot
  has_many :qcables

  validates_presence_of :user, :lot

  attr_accessor :count

  after_create :make_qcables!

  def make_qcables!
    lot.qcables.build([{:qcable_creator=>self}]*count).tap do |_|
      lot.save!
    end
  end

end
