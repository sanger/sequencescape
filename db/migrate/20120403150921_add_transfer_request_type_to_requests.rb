class AddTransferRequestTypeToRequests < ActiveRecord::Migration

  class Requests < ActiveRecord::Base
    belongs_to :request_type
    named_scope :transfer_requests, :conditions => { :sti_type => 'TransferRequest' }
  end

  class RequestType < ActiveRecord::Base
    has_many :requests
  end

  def self.up
    ActiveRecord::Base.transaction do
      transfer_request_type = RequestType.find_by_key('transfer').id
      Requests.update_all({:request_type_id => transfer_request_type}, ["sti_type = ?",'TransferRequest'])
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Requests.update_all({:request_type_id => nil}, ["sti_type = ?",'TransferRequest'])
    end
  end
end
