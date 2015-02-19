#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
ActiveRecord::Base.transaction do

  excluded = ['Dilution Plates']

  PlatePurpose.find_all_by_qc_display(true).each do |plate_purpose|
    Plate::Creator.create!(:plate_purpose => plate_purpose, :name => plate_purpose.name).tap do |creator|
      creator.plate_purposes = plate_purpose.child_plate_purposes
    end unless excluded.include?(plate_purpose.name)
  end

  # Additional plate purposes required
  [ 'Pico dilution', 'Working dilution' ].each do |name|
    plate_purpose = PlatePurpose.find_by_name(name) or raise StandardError, "Cannot find #{name.inspect} plate purpose"
    Plate::Creator.create!(:name => name, :plate_purpose => plate_purpose, :plate_purposes => [ plate_purpose ])
  end
end
