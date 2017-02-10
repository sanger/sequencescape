class UpdateBespokeTemplatesToUseOwnRequestTypes < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      rt = RequestType.find_by(key: 'bespoke_hiseq_x_paired_end_sequencing')
      ['Illumina-C - General no PCR - HiSeq-X sequencing', 'Illumina-C - General PCR - HiSeq-X sequencing'].each do |name|
        st = SubmissionTemplate.find_by!(name: name)
        st.submission_parameters[:request_type_ids_list][1] = [rt.id]
        st.save!
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      rt = RequestType.find_by(key: 'illumina_b_hiseq_x_paired_end_sequencing')
      ['Illumina-C - General no PCR - HiSeq-X sequencing', 'Illumina-C - General PCR - HiSeq-X sequencing'].each do |name|
        st = SubmissionTemplate.find_by!(name: name)
        st.submission_parameters[:request_type_ids_list][1] = [rt.id]
        st.save!
      end
    end
  end
end
