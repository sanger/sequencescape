# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Event::SequenomLoading < Event
  def self.created_update_gender_makers!(asset, resource)
    create!(
      eventful: asset,
      message: "Updated gender results from #{resource}",
      content: resource,
      family: 'update_gender_markers'
    )
  end

  def self.created_update_sequenom_count!(asset, resource)
    create!(
      eventful: asset,
      message: "Updated sequenom results from #{resource}",
      content: resource,
      family: 'update_sequenom_count'
    )
  end

  def self.updated_fluidigm_plate!(asset, resource)
    create!(
      eventful: asset,
      message: "Updated fluidigm plate from #{resource}",
      content: resource,
      family: 'update_fluidigm_plate'
    )
  end
end
