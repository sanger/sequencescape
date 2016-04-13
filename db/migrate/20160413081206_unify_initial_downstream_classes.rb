class UnifyInitialDownstreamClasses < ActiveRecord::Migration

  class Request < ActiveRecord::Base
    self.table_name = 'requests'
  end

  NEW_CLASS = 'TransferRequest::InitialDownstream'
  OLD_CLASSES = ['IlluminaHtp::Requests::PcrXpToPoolPippin','IlluminaHtp::Requests::PcrXpToPool']

  def up
    ActiveRecord::Base.transaction do
      OLD_CLASSES.each do |old|
        RequestType.where(request_class_name:old).find_each do |rt|
          say "Updating: #{rt.name}"
          rt.update_attributes!(request_class_name:NEW_CLASS)
          upd = Request.where(request_type_id:rt.id,sti_type:old).update_all(sti_type:NEW_CLASS)
          say "Updated #{upd} requests", true
        end
      end
    end
  end

  def down
  end
end
