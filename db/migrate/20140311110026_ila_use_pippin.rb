class IlaUsePippin < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find(:all,:conditions=>"name LIKE 'Illumina-A % Pooled %'").each do |st|
        new_name = st.name.gsub('Pooled','Pippin WGS')
        sp = st.submission_parameters
        sp[:request_type_ids_list][-2] = [RequestType.find_by_key('illumina_a_pippin').id]
        st.update_attributes!(:name=>new_name,:submission_parameters=>sp)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find(:all,:conditions=>"name LIKE 'Illumina-A % Pippin WGS%'").each do |st|
        new_name = st.name.gsub('Pippin WGS','Pooled')
        sp = st.submission_parameters
        sp[:request_type_ids_list][-2] = [RequestType.find_by_key('illumina_a_pooled').id]
        st.update_attributes!(:name=>new_name,:submission_parameters=>sp)
      end
    end
  end



end
