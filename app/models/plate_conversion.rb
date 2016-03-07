#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
# Creating an instance of this class causes the target to become converted to the new
# plate purpose
class PlateConversion < ActiveRecord::Base

  include Uuid::Uuidable

  belongs_to :target, :class_name => 'Plate'
  belongs_to :user
  belongs_to :purpose, :class_name => 'PlatePurpose'

  belongs_to :parent, :class_name => 'Plate'

  validates :target, :presence => true
  validates :purpose, :presence => true
  validates :user, :presence =>true

  after_create :convert_target

  private

  def convert_target
    target.convert_to(purpose)
    AssetLink.create!(:ancestor_id => parent.id, :descendant_id => target.id) if parent.present?
  end

end
