
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
