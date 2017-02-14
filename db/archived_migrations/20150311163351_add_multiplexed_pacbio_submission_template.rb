# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
class AddMultiplexedPacbioSubmissionTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.create!( {
        :name => "Multiplexed PacBio",
        :submission_class_name => 'LinearSubmission',
        :submission_parameters => { :request_type_ids_list=>['pacbio_tagged_library_prep','pacbio_multiplexed_sequencing'].map{|key| RequestType.find_by_key(key).id},
        :workflow_id => 1 }
        })
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by_name("Multiplexed PacBio").destroy
    end
  end
end
