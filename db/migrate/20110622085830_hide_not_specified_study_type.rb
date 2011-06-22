class HideNotSpecifiedStudyType < ActiveRecord::Migration
  class StudyType < ActiveRecord::Base
    set_table_name('study_types')
  end

  def self.set_valid_for_creation_to(state)
    StudyType.update_all("valid_for_creation=#{state.to_s.upcase}", [ 'name=?', 'Not specified' ])
  end

  def self.up
    set_valid_for_creation_to(false)
  end

  def self.down
    set_valid_for_creation_to(true)
  end
end
