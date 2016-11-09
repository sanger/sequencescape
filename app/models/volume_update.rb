# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012,2013,2015 Genome Research Ltd.

# Performs a change of volume on a resource
#
#--
#++
class VolumeUpdate < ActiveRecord::Base
  include Uuid::Uuidable

  validates_presence_of :created_by

  # This is the target asset for which to update the state
  # belongs_to :target, :class_name => 'Asset'
  belongs_to :target, class_name: 'Asset', foreign_key: :target_id
  validates_presence_of :target

  validates_presence_of :volume_change

  after_create :update_volume_change_of_target
  def update_volume_change_of_target
    # So we can modify any asset's volume
    target.update_volume(volume_change)
  end
  private :update_volume_change_of_target

end
