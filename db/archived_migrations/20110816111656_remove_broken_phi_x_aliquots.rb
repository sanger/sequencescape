#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class RemoveBrokenPhiXAliquots < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      # Remove any aliquots that have been bound to a receptacle that has since disappeared, for some reason.
      Sample.find_by_name('phiX_for_spiked_buffers').aliquots.each do |aliquot|
        aliquot.destroy if aliquot.receptacle_id.nil? or aliquot.receptacle.nil?
      end
    end
  end

  def self.down
    # Doesn't need to do anything on the down
  end
end
