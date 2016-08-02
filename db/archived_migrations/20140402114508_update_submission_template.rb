#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class UpdateSubmissionTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by_name('MiSeq for TagQC').tap do |st|
        sp = st.submission_parameters
        sp[:request_type_ids_list] = [[RequestType.find_by_key('qc_miseq_sequencing').id]]
        st.update_attributes!(:submission_parameters=>sp)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by_name('MiSeq for TagQC').tap do |st|
        sp = st.submission_parameters
        sp[:request_type_ids_list] = [[RequestType.find_by_key('miseq_sequencing').id]]
        st.update_attributes!(:submission_parameters=>sp)
      end
    end
  end
end
