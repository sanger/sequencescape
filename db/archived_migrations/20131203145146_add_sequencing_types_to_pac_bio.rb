#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddSequencingTypesToPacBio < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by_name('PacBio').tap do |pac_bio|
        sub_param = pac_bio.submission_parameters.clone
        sub_param[:input_field_infos].detect {|ifi| ifi.display_name == 'Sequencing type' }.selection.delete('Strobe')
        sub_param[:input_field_infos].detect {|ifi| ifi.display_name == 'Sequencing type' }.selection.delete('Circular')
        sub_param[:input_field_infos].detect {|ifi| ifi.display_name == 'Sequencing type' }.selection << 'MagBead'
        pac_bio.update_attributes!(:submission_parameters=>sub_param)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by_name('PacBio').tap do |pac_bio|
        sub_param = pac_bio.submission_parameters.clone
        sub_param[:input_field_infos].detect {|ifi| ifi.display_name == 'Sequencing type' }.delete('MagBead')
        sub_param[:input_field_infos].detect {|ifi| ifi.display_name == 'Sequencing type' }.selection << 'Strobe'
        sub_param[:input_field_infos].detect {|ifi| ifi.display_name == 'Sequencing type' }.selection << 'Circular'
        pac_bio.update_attributes!(:submission_parameters=>sub_param)
      end
    end
  end
end
