# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class AddSubmssionTemplateForQc < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by(name: 'MiSeq for TagQC').tap do |st|
        new_st = st.clone
        new_st.name = 'MiSeq for QC'
        new_st.save!
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by(name: 'MiSeq for QC').destroy
    end
  end
end
