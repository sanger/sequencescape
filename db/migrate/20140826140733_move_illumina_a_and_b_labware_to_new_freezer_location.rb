#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class MoveIlluminaAAndBLabwareToNewFreezerLocation < ActiveRecord::Migration

  def self.plate_purposes
    names = IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS.flatten.concat(IlluminaHtp::PlatePurposes::PLATE_PURPOSE_FLOWS.flatten)
    PlatePurpose.find_all_by_name(names)
  end

  def self.stock_plate_purposes
    PlatePurpose.find_all_by_name([IlluminaB::PlatePurposes::STOCK_PLATE_PURPOSE,IlluminaHtp::PlatePurposes::STOCK_PLATE_PURPOSE])
  end

  def self.freezer
    freezer_name = 'Illumina high throughput freezer'
    Location.find_by_name(freezer_name) or raise ActiveRecord::RecordNotFound, freezer_name
  end

  def self.up
    ActiveRecord::Base.transaction do
      illumina_freezer = self.freezer
      ['Library creation freezer', 'Pulldown freezer'].map do |freezer_name|
        Location.find_by_name(freezer_name)
      end.each do |location|
        changed = 0

        plate_ids = Plate.with_plate_purpose(self.plate_purposes).
                          with_no_outgoing_transfers.
                          located_in(location).
                          find(:all,:select=>'assets.id').map(&:id)
        say "Found #{plate_ids.length} plate ids."
        Plate.find_each(:conditions=>{:id=>plate_ids}) do |plate|
          plate.update_attributes(:location => illumina_freezer)
          changed += 1
        end
        say "Moved #{changed} plates from #{location.name}"
      end
    end
  end

  def self.down
  end
end
