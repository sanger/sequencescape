
class AddRequestPurposeToRequests < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.reset_column_information
      RequestType.find_each do |rt|
        say "Updating #{rt.name} requests"
        rt.requests.update_all(request_purpose_id: rt.request_purpose.id)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Request.update_all(request_purpose_id: nil)
    end
  end
end
