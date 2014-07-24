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
