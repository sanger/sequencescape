#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class IncreaseLengthOfTagLayoutSubstitutions < ActiveRecord::Migration
  def self.up
    change_column 'tag_layouts', 'substitutions', :string, :limit => 1525
  end

  def self.down
    change_column 'tag_layouts', 'substitutions', :string, :limit => 255
  end
end
