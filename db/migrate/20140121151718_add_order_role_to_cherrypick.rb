class AddOrderRoleToCherrypick < ActiveRecord::Migration
  def self.up
    st = SubmissionTemplate.find_by_name('Cherrypick')
    sp = st.submission_parameters
    sp[:input_field_infos] = [
      FieldInfo.new(
        :display_name => 'Plate identifier',
        :type => 'Selection',
        :key => 'order_role'
        ).tap do |fi|
          fi.set_selection([
            '',
            'ILA WGS',
            'ILA ISC',
            'ILB HWGS',
            'ILB PATH'
        ])
        end
    ]
    st.update_attributes!(:submission_parameters=>sp)
  end

  def self.down
    st = SubmissionTemplate.find_by_name('Cherrypick')
    sp = st.submission_parameters
    sp.delete(:input_field_infos)
    st.update_attributes!(:submission_parameters=>sp)
  end
end
