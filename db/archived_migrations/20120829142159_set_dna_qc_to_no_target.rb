#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class SetDnaQcToNoTarget < ActiveRecord::Migration
  def self.up
    RequestType.find_by_key('dna_qc').update_attributes!(:no_target_asset => true)
  end

  def self.down
    RequestType.find_by_key('dna_qc').update_attributes!(:no_target_asset => false)
  end
end
