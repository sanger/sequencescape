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
