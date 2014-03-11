class UpdatePacbioFragmentSize < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by_name('PacBio').tap do |pac_bio|
        sub_param = pac_bio.submission_parameters.clone
        sub_param[:input_field_infos].detect {|ifi| ifi.display_name == 'Insert size' }.set_selection [
          '500', '1000', '2000', '5000', '10000', '20000']
        pac_bio.update_attributes!(:submission_parameters=>sub_param)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by_name('PacBio').tap do |pac_bio|
        sub_param = pac_bio.submission_parameters.clone
        sub_param[:input_field_infos].detect {|ifi| ifi.display_name == 'Insert size' }.set_selection [
          '200','250','500', '1000', '2000','4000','6000', '8000','10000']
        pac_bio.update_attributes!(:submission_parameters=>sub_param)
      end
    end
  end
end
