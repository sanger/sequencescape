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
