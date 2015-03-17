#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddDefaultLibraryTypeToRerequestTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by_name!('HiSeq-X library re-sequencing').tap do |template|
        template.submission_parameters[:request_options]={"library_type"=>"Standard"}
      end.save!
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by_name!('HiSeq-X library re-sequencing').tap do |template|
        template.submission_parameters.delete(:request_options)
      end.save!
    end
  end
end
