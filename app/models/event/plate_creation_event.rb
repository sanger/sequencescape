#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class Event::PlateCreationEvent < Event
  def self.create_for_asset!(asset, plate_purpose, child_plate, user)
    self.create!(
      :eventful => asset,
      :message => "Created child #{plate_purpose.name} plate",
      :content => Date.today.to_s,
      :family => "create_#{plate_purpose.class.name.underscore}",
      :created_by => user ? user.login : nil
    )
    self.create!(
      :eventful => child_plate,
      :message => "Created #{plate_purpose.name} plate",
      :content => Date.today.to_s,
      :family => "create_#{plate_purpose.class.name.underscore}",
      :created_by => user ? user.login : nil
    )
  end

  def self.create_for_asset_with_date!(asset, plate_purpose, parent_plate, date)
    self.create!(
      :eventful => asset,
      :message => "Created #{plate_purpose.name} from #{parent_plate.id}",
      :content => date.to_s,
      :family => "create_#{plate_purpose.class.name.underscore}"
    )
  end

  def self.create_sequenom_stamp_for_asset!(asset, user)
    self.create!(
      :eventful => asset,
      :message => "Stock plate appears on a plate for Sequenom",
      :content => Date.today.to_s,
      :family => "create_for_sequenom",
      :created_by => user ? user.login : nil
    )
  end
  def self.create_sequenom_plate_for_asset!(asset, user)
    self.create!(
      :eventful => asset,
      :message => "Created Sequenom plate",
      :content => Date.today.to_s,
      :family => "create_sequenom_plate",
      :created_by => user ? user.login : nil
    )
  end

end
