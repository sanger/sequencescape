class IlluminaCCherrypickRequestsShouldBeRightClass < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.find_by_key('illumina_c_cherrypick').update_attributes!(:request_class_name=>'CherrypickForPulldownRequest')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key('illumina_c_cherrypick').update_attributes!(:request_class_name=>'Request')
    end
  end
end
