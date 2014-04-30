class UpdateCherrypickRequestTypes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.find_by_name('Cherrypick').update_attributes!(:request_class_name => 'CherrypickForPulldownRequest')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_name('Cherrypick').update_attributes!(:request_class_name => 'Request')
    end
  end
end
